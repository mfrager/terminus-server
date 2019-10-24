:- module(validate, [
              schema_transaction/4,
              document_transaction/5
          ]).

/** <module> Validation
 * 
 * Implements schema and instance validation
 * 
 * * * * * * * * * * * * * COPYRIGHT NOTICE  * * * * * * * * * * * * * * *
 *                                                                       *
 *  This file is part of TerminusDB.                                     *
 *                                                                       *
 *  TerminusDB is free software: you can redistribute it and/or modify   *
 *  it under the terms of the GNU General Public License as published by *
 *  the Free Software Foundation, under version 3 of the License.        *
 *                                                                       *
 *                                                                       *
 *  TerminusDB is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of       *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        *
 *  GNU General Public License for more details.                         *
 *                                                                       *
 *  You should have received a copy of the GNU General Public License    *
 *  along with TerminusDB.  If not, see <https://www.gnu.org/licenses/>. *
 *                                                                       *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

:- use_module(library(triplestore)).
:- use_module(library(database)).
:- use_module(library(journaling)).
:- use_module(library(utils)).
:- use_module(library(validate_schema)).
:- use_module(library(validate_instance)).
:- use_module(library(frame)).
:- use_module(library(jsonld)).
:- use_module(library(semweb/turtle)).

:- use_module(library(literals)).

% For debugging
:- use_module(library(http/http_log)).

% Required for consistency
pre_test_schema(classCycleSC).
pre_test_schema(propertyCycleSC).

/** 
 * test_schema(-Pred:atom) is nondet.
 * 
 * This predicate gives each available schema constraint.
 */
% Restrictions on schemas 
test_schema(noImmediateClassSC).
test_schema(noImmediateDomainSC).
test_schema(noImmediateRangeSC).
%test_schema(notUniqueClassLabelSC).
%test_schema(notUniqueClassSC).
%test_schema(notUniquePropertySC). % still useful with annotationOverloadSC?
%test_schema(schemaBlankNodeSC). % should never be used.
test_schema(annotationOverloadSC).
% OWL DL constraints
test_schema(orphanClassSC).
test_schema(orphanPropertySC). 
test_schema(invalidRangeSC). 
test_schema(invalidDomainSC).
test_schema(domainNotSubsumedSC).
test_schema(rangeNotSubsumedSC).
test_schema(propertyTypeOverloadSC).
test_schema(invalid_RDFS_property_SC).

/* 
 * schema_transaction(+Database,-Database,+Schema,+New_Schema_Stream, Witnesses) is det.
 * 
 * Updates a schema using a turtle formatted stream.
 */ 
schema_transaction(Database, Schema, New_Schema_Stream, Witnesses) :-
    % make a fresh empty graph against which to diff
    open_memory_store(Store),
    open_write(Store, Builder),

    % write to a temporary builder.
    rdf_process_turtle(
        New_Schema_Stream,
        {Builder}/
        [Triples,_Resource]>>(
            forall(member(T, Triples),
                   (   normalise_triple(T, rdf(X,P,Y)),
                       nb_add_triple(Builder, X, P, Y)))),
        []),
    % commit this builder to a temporary layer to perform a diff.
    nb_commit(Builder,Layer),
    
    with_transaction(
        [transaction_record{
             pre_database: Database,
             write_graphs: [Schema],
             update_database: Update_DB,
             post_database: Post_DB},
         witnesses(Witnesses)],
        % Update
        validate:(
            % first write everything into the layer-builder that is in the new
            % file, but not in the db. 
            (   xrdf(Update_DB,[Schema], A, B, C),
                \+ xrdf_db(Layer,X,Y,Z)
            ->  delete(Update_DB,Schema,X,Y,Z)
            ;   xrdf_db(Layer,X,Y,Z), 
                \+ xrdf(Update_DB,[Schema], A, B, C)
            ->  insert(Update_DB,Schema,X,Y,Z)
            ;   true % in both
            )
        ),
        % Post conditions
        validate:(
            findall(Pre_Witness,
                    (   pre_test_schema(Pre_Check),
                        call(Pre_Check,Post_DB,Pre_Witness)),
                    Pre_Witnesses),
            (   \+ Pre_Witnesses = []
            % We have witnesses of failure and must bail
            ->  Witnesses = Pre_Witnesses
            % We survived the pre_tests, better check schema constriants
            ;   findall(Schema_Witness,
                        (   test_schema(Check),
                            call(Check,Post_DB,Schema_Witness)),
                        Schema_Witnesses),
                (   \+ Schema_Witnesses = []
                ->  Witnesses = Schema_Witnesses
                    % Winning!
                ;   % TODO: We do not need to perform a global check of instances
                    % Better would be a local check derived from schema delta.
                    findall(Witness,
                            (   Instances = Post_DB.instances,
                                xrdf(Post_DB,Instances,E,F,G),
                                refute_insertion(Post_DB,E,F,G,Witness)),
                            Witnesses)
                
                )
            )
        )
    ).

/* 
 * document_transaction(Database:database, Transaction_Database:database, Graph:graph_identifier,   
 *                      Document:json_ld, Witnesses:json_ld) is det.
 * 
 * Update the database with a document, or fail with a constraint witness. 
 * 
 */
document_transaction(Database, Update_Database, Graph, Goal, Witnesses) :-
    with_transaction(
        [transaction_record{
             pre_database: Database,
             update_database: Update_Database,
             post_database: Post_Database,
             write_graphs: [Graph]},       
         witnesses(Witnesses)],
        Goal,
        validate:(   findall(Pos_Witness,
                             (
                                 triplestore:xrdf_added(Post_Database, [Graph], X, P, Y),
                                 refute_insertion(Post_Database, X, P, Y, Pos_Witness)
                             ),
                             Pos_Witnesses),
                     
                     findall(Neg_Witness,
                             (   
                                 triplestore:xrdf_deleted(Post_Database, [Graph], X, P, Y),
                                 refute_deletion(Post_Database, X, P, Y, Neg_Witness)
                             ),
                             Neg_Witnesses),
                     Neg_Witnesses = [],
                     
                     append(Pos_Witnesses, Neg_Witnesses, Witnesses)            
                 )
    ).
