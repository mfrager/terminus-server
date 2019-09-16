:- module(validate, [
              schema_update/4
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
 *  the Free Software Foundation, either version 3 of the License, or    *
 *  (at your option) any later version.                                  *
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
:- use_module(library(json_ld)).

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
test_schema(notUniqueClassLabelSC).
test_schema(notUniqueClassSC).
test_schema(notUniquePropertySC). % still useful with annotationOverloadSC?
test_schema(schemaBlankNodeSC).
test_schema(annotationOverloadSC).
% OWL DL constraints
test_schema(orphanClassSC).
test_schema(orphanPropertySC). 
test_schema(invalidRangeSC). 
test_schema(invalidDomainSC).
test_schema(domainNotSubsumedSC).
test_schema(rangeNotSubsumedSC).
test_schema(propertyTypeOverloadSC).

schema_update(Database, Schema, New_Schema_Stream, Witnesses) :-
    database_name(Database,Database_Name),
    with_transaction(
        [collection(Database_Name),
         graphs([Schema]),
         success(Success_Flag)],
        (
            % deletes (everything)
            forall( xrdf(Database_Name, [Schema], A, B, C),
                    delete(Database_Name, Schema, A,B,C)),
            
            % inserts (everything)
            rdf_process_turtle(New_Schema_Stream,
                               {Database_Name, Schema}/
                               [rdf(X,P,Y),_Resource]>>(
                                   (   X = node(N)
                                   ->  interpolate(['_:',N], XF)
                                   ;   X = XF),
                                   (   Y = node(N)
                                   ->  interpolate(['_:',N], YF)
                                   ;   Y = YF),
                                   insert(Database_Name,Schema,XF,P,YF)
                               ), []),
            
            % First, Check pre tests. 
            (   findall(Pre_Witness,
                        (   pre_test_schema(Pre_Check),
                            call(Pre_Check,Database,Pre_Witness)),
                        Pre_Witnesses)
            ->  Success_Flag = false,
                Witnesses = Pre_Witnesses
                % We survived the pre_tests, better check schema constriants
            ;   (   findall(Schema_Witness,
                            (   test_schema(Check),
                                call(Check,Database,Schema_Witness)),
                            Schema_Witnesses)
                ->  Success_Flag = false,
                    append(Pre_Witnesses, Schema_Witnesses, Witnesses)
                    % Winning!
                ;   Success_Flag = true,
                    Witnesses = []
                )
            )
        )
    ).
