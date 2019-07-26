/**
 * Define DQL grammar
 */
grammar DQL;

dql_stmt: (select_stmt|alter_group_stmt|create_group_stmt|drop_group_stmt|alter_type_stmt|create_type_stmt|drop_type_stmt|create_object_stmt|update_object_stmt|insert_stmt|update_stmt|execute_stmt|grant_stmt|revoke_stmt|change_object_stmt|delete_object_stmt|delete_stmt) SCOL?;
 
 select_stmt: K_SELECT (K_FOR (K_BROWSE | K_READ | K_RELATE | K_WRITE | K_DELETE))? ( K_DISTINCT | K_ALL )? result_column ( COMMA result_column )*
    K_FROM ( table_or_subquery ( COMMA table_or_subquery )* ) (K_WITH expr)? in_partition? in_document_or_assembly? search_clause?
   ( K_WHERE qualification )?
   ( K_GROUP K_BY column_name ( COMMA column_name)* ( K_HAVING (aggregate|count)( '<' | '<=' | '>' | '>=' | '=' ) NUMERIC_LITERAL )? )?  (hint_function)?
 ;
 
 alter_group_stmt:
 K_ALTER K_GROUP any_name (K_ADD|K_DROP) (any_name (COMMA any_name)*| OPEN_PAR select_stmt CLOSE_PAR)
 |K_ALTER K_GROUP any_name K_SET K_ADDRESS any_name
 |K_ALTER K_GROUP any_name K_SET K_PRIVATE boolean_value
 ;
 
 create_group_stmt:
 K_CREATE (K_PUBLIC|K_PRIVATE)? K_GROUP any_name (K_WITH)? (K_ADDRESS STRING_LITERAL)? 
 ( K_MEMBERS (any_name (COMMA any_name)*| OPEN_PAR select_stmt CLOSE_PAR))?
 ;
 
 drop_group_stmt:
 K_DROP K_GROUP any_name
 ;
 
//TODO 
//ALTER TYPE type_name
//[FOR POLICY policy_id STATE state_name]
//type_modifier_list [PUBLISH]
//
//ALTER TYPE type_name
//[FOR POLICY policy_id STATE state_name]
//MODIFY (property_modifier_clause)[PUBLISH]
//
//ALTER TYPE type_name
//ADD property_def {,property_def}[PUBLISH]
//
//ALTER TYPE type_name
//DROP property_def {,property_def}[PUBLISH]
//
//ALTER TYPE type_name ALLOW ASPECTS
//
//ALTER TYPE type_name
//ADD|SET|REMOVE DEFAULT ASPECTS aspect_list
//
//ALTER TYPE type_name ENABLE PARTITION
//
//ALTER TYPE type_name SHAREABLE [PUBLISH]
//
//ALTER TYPE type_name FULLTEXT SUPPORT 
//[NONE |LITE ADD ALL|LITE ADD property_list |BASE ADD ALL |BASE ADD property_list]
 alter_type_stmt:
  K_ALTER K_TYPE type_name for_policy? type_modifier_list 
 |K_ALTER K_TYPE type_name for_policy? K_MODIFY OPEN_PAR ((property_name OPEN_PAR update_list (COMMA update_list)* CLOSE_PAR) |property_modifier_list)? CLOSE_PAR K_PUBLISH?
 |K_ALTER K_TYPE type_name (K_ADD|K_DROP) property_def (COMMA  property_def)* K_PUBLISH?
 |K_ALTER K_TYPE type_name K_ALLOW K_ASPECTS
 |K_ALTER K_TYPE type_name (K_ADD|K_SET|K_REMOVE) K_DEFAULT K_ASPECTS aspect_list
 |K_ALTER K_TYPE type_name K_ENABLE K_PARTITION
 |K_ALTER K_TYPE type_name K_SHAREABLE K_PUBLISH?
 |K_ALTER K_TYPE type_name fulltext_support
 ;

//TODO ASPECTS, CONSTRAINTS... 
 create_type_stmt:
 (K_CREATE (K_PARTITIONABLE|K_SHAREABLE)? K_TYPE type_name K_WITH? (K_SUPERTYPE (type_name|K_NULL))? 
 ( K_MEMBERS (property_def (COMMA property_def)*| OPEN_PAR select_stmt CLOSE_PAR))? K_PUBLISH?)
 | (K_CREATE K_LIGHTWEIGHT K_TYPE type_name (property_def (COMMA  property_def)*)? K_SHARES type_name ((K_AUTO K_MATERIALIZATION)|(K_MATERIALIZATION K_ON K_REQUEST)|(K_DISALLOW K_MATERIALIZATION) )
 (fulltext_support)? K_PUBLISH) 
 ;
 
 drop_type_stmt:
 K_DROP K_TYPE type_name
 ;


//CREATE type_name OBJECT update_list
//[,SETFILE 'filepath' WITH CONTENT_FORMAT='format_name']
//{,SETFILE 'filepath' WITH PAGE_NO=page_number}
create_object_stmt:
K_CREATE type_name K_OBJECT update_list (COMMA update_list)* setfile? 
;
 
// UPDATE [PUBLIC]type_name [(ALL)][correlation_var]
// [WITHIN PARTITION partition_id {,partition_id}]
// OBJECT[S] update_list
// [,SETFILE filepath WITH CONTENT_FORMAT=format_name]
// {,SETFILE filepath WITH PAGE_NO=page_number}
// [IN ASSEMBLY document_id [VERSION version_label][NODE component_id] [DESCEND]]
// [SEARCH fulltext search condition]
// [WHERE qualification]
 update_object_stmt:
 K_UPDATE type_name all? any_name? in_partition? (K_OBJECT|K_OBJECTS) update_list (COMMA update_list)* setfile? in_assembly? search_clause? (K_WHERE qualification)?
 ;

 // INSERT INTO table_name [(column_name {,column_name})] 
 // VALUES (value {,value}) | dql_subselect
 insert_stmt:
 K_INSERT K_INTO type_name column_name (COMMA column_name)* K_VALUES ((OPEN_PAR literal_value (COMMA literal_value)* CLOSE_PAR)| select_stmt )
 ;
   
// UPDATE table_name SET column_assignments
// [WHERE qualification]
 update_stmt:
 K_UPDATE type_name K_SET expr_simple EQU literal_value (K_WHERE qualification)?
 ;
  
// EXECUTE admin_method_name [[FOR] object_id]
// [WITH argument = value {,argument = value}]	
 execute_stmt:
 K_EXECUTE admin_methods (K_FOR? STRING_LITERAL)? (K_WITH IDENTIFIER EQU literal_value (COMMA IDENTIFIER EQU literal_value)* )
 ;
 
 grant_stmt:
 K_GRANT privilege (COMMA privilege)* K_TO STRING_LITERAL (COMMA STRING_LITERAL)*
 ;
 
 revoke_stmt:
 K_REVOKE privilege (COMMA privilege)* K_FROM STRING_LITERAL (COMMA STRING_LITERAL)*
 ;
 
//CHANGE current_type [(ALL)] OBJECT[S]
//TO new_type[update_list]
//[IN ASSEMBLY document_id [VERSION version_label] [DESCEND]]
//[SEARCH fulltext search condition]
//[WHERE qualification]
 change_object_stmt:
 K_CHANGE type_name all? (K_OBJECT|K_OBJECTS) K_TO type_name (update_list|link_list) (COMMA? (update_list|link_list))? in_assembly search_clause (K_WHERE qualification)? 
 ;

// DELETE [PUBLIC]type_name[(ALL)]
// [correlation_variable]
// [WITHIN PARTITION (partition_id {,partition_id})
// OBJECT[S]
// [IN ASSEMBLY document_id [VERSION version_label]
// [NODE component_id][DESCEND]]
// [SEARCH fulltext search condition]
// [WHERE qualification]
 delete_object_stmt:
  K_DELETE type_name all? any_name? in_partition? (K_OBJECT|K_OBJECTS) in_assembly? search_clause? (K_WHERE qualification)?
 ;
 
 // DELETE FROM table_name WHERE qualification
 delete_stmt:
 K_DELETE K_FROM type_name (K_WHERE qualification)?
 ;
 
// REGISTER TABLE [owner_name.]table_name
// (column_def {,column_def})
// [[WITH] KEY (column_list)]
// [SYNONYM [FOR] 'table_identification']
 register_stmt:
 K_REGISTER K_TABLE (IDENTIFIER '.')? type_name OPEN_PAR column_def (COMMA column_def)* CLOSE_PAR  (K_WITH? K_KEY column_name (COMMA column_name)*) (K_SYNONYM K_FOR? type_name)?
 ;
 
 //UNREGISTER [TABLE] [owner_name.]table_name
 unregister_stmt:
 K_UNREGISTER K_TABLE? (repo_owner '.')? type_name
 ;
 
 update_type_modifier:
  property_name OPEN_PAR update_list (COMMA update_list)* CLOSE_PAR
  |K_SET K_DEFAULT K_ACL (STRING_LITERAL|K_NULL) (K_IN STRING_LITERAL)?
  |K_SET K_DEFAULT K_STORAGE EQU? STRING_LITERAL
  |K_SET K_DEFAULT K_GROUP EQU? (STRING_LITERAL|K_NULL)
  |K_SET K_DEFAULT K_BUSINESS K_POLICY EQU? STRING_LITERAL (K_VERSION STRING_LITERAL)?
 ;
 
 update_list:
  K_SET property_name repeating_index? '=' (literal_value| OPEN_PAR select_stmt CLOSE_PAR)
 |K_APPEND repeating_index? property_name '=' (literal_value| OPEN_PAR select_stmt CLOSE_PAR)
 |K_INSERT property_name repeating_index? '=' (literal_value| OPEN_PAR select_stmt CLOSE_PAR)
 |K_REMOVE property_name repeating_index?
 |K_TRUNCATE property_name repeating_index?
 ;

link_list:
 K_LINK STRING_LITERAL
 |K_UNLINK STRING_LITERAL
 |K_MOVE K_TO? STRING_LITERAL
 ;
 
 setfile:
 K_SETFILE STRING_LITERAL K_WITH K_CONTENT_FORMAT '=' STRING_LITERAL
 (COMMA K_SETFILE STRING_LITERAL K_WITH K_PAGE_NO '=' NUMERIC_LITERAL)*
 ;
 
 property_def:
 property_name domain K_REPEATING? (K_NOT? (K_QUALIFIABLE|K_SPACEOPTIMIZE))? property_modifier_list?
 ;
 
 property_name:
  IDENTIFIER
 ;
 
 domain:
 |K_BOOLEAN
 |K_BOOL
 |K_CHAR OPEN_PAR NUMERIC_LITERAL CLOSE_PAR
 |K_CHARACTER OPEN_PAR NUMERIC_LITERAL CLOSE_PAR
 |K_STRING OPEN_PAR NUMERIC_LITERAL CLOSE_PAR
 |K_DATE
 |K_DOUBLE
 |K_FLOAT
 |K_ID
 |K_INTEGER
 |K_SMALLINT
 |K_STRING
 |K_TIME
 |K_TINYINT
  ;
 
 for_policy:
  K_FOR K_POLICY any_name K_STATE any_name
 ;
 
 //TODO
 type_modifier_list:
  update_type_modifier
 |mapping_table_specification
 |constraint_specification
//component_specification
//type_drop_clause
 ;
 
 //TODO
 property_modifier_list:
 value_assistance_modifier
 |mapping_table_specification
 |default_specification
 |constraint_specification
 ;
 
 aspect_list:
  any_name (COMMA any_name)*
 ;
 
 fulltext_support:
 K_FULLTEXT K_SUPPORT (K_NONE|(K_LITE K_ADD K_ALL)|(K_LITE K_ADD property_name (COMMA property_name)*)|(K_BASE K_ADD K_ALL)|(K_LITE K_ADD property_name (COMMA property_name)*))?
 ;
 
//VALUE ASSISTANCE IS
//[IF (expression_string)
//va_clause
//(ELSEIF (expression_string)
//va_clause)
//ELSE]
//va_clause
//[DEPENDENCY LIST ([property_list])
 value_assistance_modifier:
 K_VALUE K_ASSISTANCE K_IS (K_IF OPEN_PAR expr CLOSE_PAR va_clause (K_ELSEIF OPEN_PAR expr CLOSE_PAR va_clause)* K_ELSE) va_clause 
 (K_DEPENDENCY K_LIST OPEN_PAR property_name (COMMA property_name)? CLOSE_PAR)
 ;
 
//for list:
//LIST (literal_list)
//[VALUE ESTIMATE=number]
//[IS [NOT] COMPLETE]
//for query:
//QRY 'query_string'
//[QRY ATTR = property_name]
//[ALLOW CACHING]
//[VALUE ESTIMATE=number]
//[IS [NOT] COMPLETE]
 va_clause:
 //TODO
 ;
 
 //TODO
 mapping_table_specification:
 K_MAPPING K_TABLE
 ;
 
 //TODO
 default_specification:
 K_DEFAULT;
 
 //TODO
 constraint_specification:
 K_CHECK OPEN_PAR expr CLOSE_PAR;
 
 search_clause
 : K_SEARCH (K_FIRST|K_LAST)? search_string
 ;
  
 search_string:
 	 K_DOCUMENT K_CONTAINS K_NOT?  STRING_LITERAL ((K_AND|K_OR) K_NOT? STRING_LITERAL)*
 ;
  
 in_partition
 : K_WITHIN K_PARTITION function_id (COMMA function_id)*
 ;
 
 in_document_or_assembly
 : (K_DOCUMENT|K_ASSEMBLY) function_id (K_VERSION any_name)? K_DESCEND? (K_WITH expr)? (K_NODESORT K_BY column_name (COMMA column_name)* sort_order?)?
 ;

 in_assembly
 : (K_ASSEMBLY) function_id (K_VERSION any_name)? (K_NODE function_id)? K_DESCEND?
 ;
    

sort_order
: K_ASC|K_DESC
;
  
table_or_subquery
 : ( repo_owner COMMA )? type_name all? ( table_alias )?
 | OPEN_PAR select_stmt CLOSE_PAR ( table_alias )?
 ;
 
qualification:
  OPEN_PAR qualification ((K_AND|K_OR) qualification)+ CLOSE_PAR
  | qualification ((K_AND|K_OR) qualification)+
  | expr
; 
 
expr
 : function_predicate
 | expr_simple ( '<' | '<=' | '>' | '>=' ) expr_simple
 | expr_simple ( '=' | '!=' | '<>' | K_IS | K_IS K_NOT | K_IN | K_LIKE ) expr_simple
 | expr_simple K_NOT? ( K_LIKE ) expr_simple ( K_ESCAPE STRING_LITERAL )?
 | expr_simple K_IS K_NOT? expr_simple
 | expr_simple K_NOT? K_IN ( '(' ( select_stmt
                          | STRING_LITERAL ( ',' STRING_LITERAL )*
                          ) 
                      ')' )
 | ( ( K_NOT )? K_EXISTS )? '(' select_stmt ')'
 | expr_simple ( '<' | '<=' | '>' | '>=' )  ( K_SOME | K_ANY | K_ALL) '(' select_stmt ')'
 ;
 
 expr_simple
 :K_ANY? column_name
 | literal_value
 | functions_call
 | unary_operator expr_simple
 | expr_simple ( '*' | '/' | '%' | '+' | '-') expr_simple
 | ( K_NULL | K_NULLID | K_NULLSTRING | K_NULLDATE | K_NULLINT )
 ;

privilege:
K_SUPERUSER
|K_SYSADMIN
|K_CREATE K_TYPE
|K_CREATE K_CABINET
|K_CREATE K_GROUP
|K_CONFIG K_AUDIT
|K_PURGE K_AUDIT
|K_VIEW K_AUDIT
;

all:
(OPEN_PAR K_ALL CLOSE_PAR)
;

function_name:
K_SUBSTR
|K_SUBSTRING
|K_LOWER
|K_UPPER
|K_ASCII
|K_BITAND
|K_BITCLR
|K_BITSET
;

functions_call:
K_SUBSTR OPEN_PAR expr_simple COMMA NUMERIC_LITERAL (COMMA NUMERIC_LITERAL)? CLOSE_PAR
| (K_UPPER|K_LOWER|K_ASCII) OPEN_PAR expr_simple CLOSE_PAR
| K_DATE OPEN_PAR ((STRING_LITERAL (COMMA STRING_LITERAL)?)|K_TODAY|K_NOW|K_TOMORROW|K_YESTERDAY) CLOSE_PAR
;

function_predicate
:
 (K_FOLDER|K_CABINET) OPEN_PAR (STRING_LITERAL|function_id) (COMMA K_DESCEND)? CLOSE_PAR
| K_TYPE OPEN_PAR STRING_LITERAL CLOSE_PAR
;

function_id
:
K_ID OPEN_PAR STRING_LITERAL CLOSE_PAR
;

functions_call_result:
K_SUBSTR OPEN_PAR column_name COMMA NUMERIC_LITERAL (COMMA NUMERIC_LITERAL)? CLOSE_PAR
| (K_UPPER|K_LOWER|K_ASCII) OPEN_PAR result_column CLOSE_PAR
;

count:
K_COUNT OPEN_PAR (K_DISTINCT? (column_name | STAR )) CLOSE_PAR
;

aggregate:
(K_MIN|K_MAX|K_AVG) OPEN_PAR K_DISTINCT? column_name CLOSE_PAR
;

unary_operator
 : MINUS
 | PLUS
 | TILDE
 | K_NOT
 ;


literal_value
 : NUMERIC_LITERAL
 | STRING_LITERAL
 | K_NULL
 | K_NOW
 | K_TODAY
 | K_YESTERDAY
 | K_USER
 | K_TRUE
 | K_FALSE
 ;
column_alias
 : IDENTIFIER
 | STRING_LITERAL
 ;
 
 column_def 
 : column_name datatype (OPEN_PAR NUMERIC_LITERAL CLOSE_PAR)?
 ;
 
 column_name 
 : (type_name DOT)? IDENTIFIER
 ;
hint_function:
K_ENABLE OPEN_PAR any_name (any_name|NUMERIC_LITERAL)* CLOSE_PAR
;

result_column
 : (result_single_col| result_single_col PLUS result_single_col)
  ( K_AS? column_alias )?
 ;
 
 datatype:
 K_FLOAT
 |K_DOUBLE
 |K_INTEGER
 |K_INT
 |K_TINYINT
 |K_SMALLINT
 |K_CHAR
 |K_CHARACTER
 |K_STRING
 |K_DATE
 |K_TIME
 ;
 
 result_single_col
 : STAR
 | literal_value
 | type_name DOT STAR
 | column_name
 | functions_call_result
 | aggregate
 | count 
 ;

repo_owner
 : any_name
;
 
type_name 
 : IDENTIFIER
;

table_alias 
 : any_name
 ;
 
 repeating_index:
 OPEN_BRACKET NUMERIC_LITERAL CLOSE_BRACKET
 ;
 
 any_name
 : IDENTIFIER 
 | STRING_LITERAL
 ;

boolean_value:
K_TRUE|K_FALSE
;

admin_methods:
IDENTIFIER
;


dql_keywords: K_ACL
| K_ASCII
| K_AND
| K_ASSEMBLY
| K_ADD
| K_ANY
| K_ASSISTANCE
| K_ADD_FTINDEX
| K_APPEND
| K_ATTR
| K_ADDRESS
| K_APPLICATION
| K_AUTO
| K_ALL
| K_AS
| K_AVG
| K_ALLOW
| K_ASC
| K_BAG
| K_BOOL
| K_BITAND
| K_BITCLR 
| K_BITSET
| K_BUSINESS
| K_BEGIN
| K_BOOLEAN
| K_BY
| K_BETWEEN
| K_BROWSE
| K_CABINET
| K_COMMENT
| K_CONTAINS
| K_CACHING
| K_COMMIT
| K_CONTENT_FORMAT
| K_CHANGE
| K_COMPLETE
| K_CONTENT_ID
| K_CHARACTER
| K_COMPONENTS
| K_COUNT
| K_CHARACTERS
| K_COMPOSITE
| K_CREATE
| K_CHAR
| K_COMPUTED
| K_CURRENT
| K_CHECK
| K_CONTAIN_ID
| K_DATE
| K_DELETED
| K_DISTINCT
| K_DATEADD
| K_DEPENDENCY
| K_DM_SESSION_DD_LOCALE
| K_DATEDIFF
| K_DEPTH
| K_DOCBASIC
| K_DATEFLOOR
| K_DESC
| K_DOCUMENT
| K_DATETOSTRING
| K_DESCEND
| K_DOUBLE
| K_DAY
| K_DISABLE
| K_DROP
| K_DEFAULT
| K_DISALLOW
| K_DROP_FTINDEX
| K_DELETE
| K_DISPLAY
| K_ELSE
| K_ENFORCE
| K_EXEC
| K_ELSEIF
| K_ESCAPE
| K_EXECUTE
| K_ENABLE
| K_ESTIMATE
| K_EXISTS
| K_FALSE
| K_FOR
| K_FT_OPTIMIZER
| K_FIRST
| K_FOREIGN
| K_FULLTEXT
| K_FLOAT
| K_FROM
| K_FUNCTION
| K_FOLDER
| K_FTINDEX
| K_GRANT
| K_GROUP
| K_HAVING
| K_HITS
| K_ID
| K_INT
| K_IS
| K_IF
| K_INTEGER
| K_ISCURRENT
| K_IN
| K_INTERNAL
| K_ISPUBLIC
| K_INSERT
| K_INTO
| K_ISREPLICA
| K_JOIN
| K_KEY
| K_LANGUAGE
| K_LIGHTWEIGHT
| K_LITE
| K_LAST
| K_LIKE
| K_LOWER
| K_LATEST
| K_LINK
| K_LEFT
| K_LIST
| K_MAPPING
| K_MEMBERS
| K_MONTH
| K_MATERIALIZE
| K_MFILE_URL
| K_MOVE
| K_MATERIALIZATION
| K_MHITS
| K_MSCORE
| K_MAX
| K_MIN
| K_MCONTENTID
| K_MODIFY
| K_NODE
| K_NOTE
| K_NULLID
| K_NODESORT
| K_NOW
| K_NULLINT
| K_NONE
| K_NULL
| K_NULLSTRING
| K_NOT
| K_NULLDATE
| K_OF
| K_ON
| K_ORDER
| K_OBJECT
| K_ONLY
| K_OUTER
| K_OBJECTS
| K_OR
| K_OWNER
| K_PAGE_NO
| K_PERMIT
| K_PRIVATE
| K_PARENT
| K_POLICY
| K_PRIVILEGES
| K_PARTITION
| K_POSITION
| K_PROPERTY
| K_PATH
| K_PRIMARY
| K_PUBLIC
| K_QRY
| K_QUALIFIABLE
| K_RDBMS
| K_RELATE
| K_REPORT
| K_READ
| K_REMOVE
| K_REQUEST
| K_REFERENCES
| K_REPEATING
| K_REVOKE
| K_REGISTER
| K_REPLACEIF
| K_SCORE
| K_SMALLINT
| K_SUPERTYPE
| K_SEARCH
| K_SOME
| K_SUPERUSER
| K_SELECT
| K_STATE
| K_SUPPORT
| K_SEPARATOR
| K_SPACEOPTIMIZE
| K_STORAGE
| K_SYNONYM
| K_SERVER
| K_STRING
| K_SYSADMIN
| K_SET
| K_SUBSTR
| K_SYSOBJ_ID
| K_SETFILE
| K_SUBSTRING
| K_SYSTEM
| K_SHAREABLE
| K_SUM
| K_SHARES
| K_SUMMARY
| K_TABLE
| K_TO
| K_TRANSACTION
| K_TAG
| K_TODAY
| K_TRUE
| K_TEXT
| K_TOMORROW
| K_TRUNCATE
| K_TIME
| K_TOPIC
| K_TYPE
| K_TINYINT
| K_TRAN
| K_UNION
| K_UNREGISTER
| K_UPDATE
| K_UNIQUE
| K_USER
| K_UPPER
| K_UNLINK
| K_USING
| K_VALUE
| K_VERSION
| K_VIOLATION
| K_VALUES
| K_VERITY
| K_WHERE
| K_WITHOUT
| K_WEEK
| K_WITH
| K_WORLD
| K_WITHIN
| K_WRITE
| K_YEAR
| K_YESTERDAY;

/* Lexer starts below */

SCOL : ';';
DOT : '.';
OPEN_PAR : '(';
CLOSE_PAR : ')';
OPEN_BRACKET : '[';
CLOSE_BRACKET : ']';
COMMA : ',';
EQU : '=';
STAR : '*';
PLUS : '+';
MINUS : '-';
TILDE : '~';
PIPE2 : '||';
DIV : '/';
MOD : '%';
LT2 : '<<';
GT2 : '>>';
AMP : '&';
PIPE : '|';
LT : '<';
LT_EQ : '<=';
GT : '>';
GT_EQ : '>=';
NOT_EQ1 : '!=';
NOT_EQ2 : '<>';


NUMERIC_LITERAL:
 DIGIT+  ('.' DIGIT+?)?  ( E [-+]? DIGIT+ )?
 | '.' DIGIT+ ( E [-+]? DIGIT+ )?
; 

STRING_LITERAL
 : '\'' ( ~'\'' | '\'\'' )* '\''
 ;
 
K_ACL : A C L;
K_AND : A N D;
K_ASSEMBLY : A S S E M B L Y;
K_ASPECTS: A S P E C T;
K_ADD : A D D;
K_ANY : A N Y;
K_ASCII : A S C I I;
K_ASSISTANCE : A S S I S T A N C E;
K_ADD_FTINDEX : A D D UNDERSCORE F T I N D E X;
K_APPEND : A P P E N D;
K_ATTR : A T T R;
K_ADDRESS : A D D R E S S;
K_APPLICATION : A P P L I C A T I O N;
K_AUTO : A U T O;
K_ALTER : A L T E R;
K_ALL : A L L;
K_AS : A S;
K_AUDIT : A U D I T;
K_AVG : A V G;
K_ALLOW : A L L O W;
K_ASC : A S C;
K_BAG : B A G;
K_BASE : B A S E;
K_BOOL : B O O L;
K_BITAND : B I T A N D;
K_BITCLR : B I T C L R;
K_BITSET : B I T S E T;
K_BUSINESS : B U S I N E S S;
K_BEGIN : B E G I N;
K_BOOLEAN : B O O L E A N;
K_BY : B Y;
K_BETWEEN : B E T W E E N;
K_BROWSE : B R O W S E;
K_CABINET : C A B I N E T;
K_COMMENT : C O M M E N T;
K_CONTAINS : C O N T A I N S;
K_CACHING : C A C H I N G;
K_COMMIT : C O M M I T;
K_CONTENT_FORMAT : C O N T E N T UNDERSCORE F O R M A T;
K_CHANGE : C H A N G E;
K_COMPLETE : C O M P L E T E;
K_CONTENT_ID : C O N T E N T UNDERSCORE I D;
K_CHARACTER : C H A R A C T E R;
K_COMPONENTS : C O M P O N E N T S;
K_COUNT : C O U N T;
K_CHARACTERS : C H A R A C T E R S;
K_COMPOSITE : C O M P O S I T E;
K_CREATE : C R E A T E;
K_CHAR : C H A R;
K_COMPUTED : C O M P U T E D;
K_CURRENT : C U R R E N T;
K_CHECK : C H E C K;
K_CONTAIN_ID : C O N T A I N UNDERSCORE I D;
K_CONFIG : C O N F I G;
K_DATE : D A T E;
K_DELETED : D E L E T E D;
K_DISTINCT : D I S T I N C T;
K_DATEADD : D A T E A D D;
K_DEPENDENCY : D E P E N D E N C Y;
K_DM_SESSION_DD_LOCALE : D M UNDERSCORE S E S S I O N UNDERSCORE D D UNDERSCORE L O C A L E;
K_DATEDIFF : D A T E D I F F;
K_DEPTH : D E P T H;
K_DOCBASIC : D O C B A S I C;
K_DATEFLOOR : D A T E F L O O R;
K_DESC : D E S C;
K_DOCUMENT : D O C U M E N T;
K_DATETOSTRING : D A T E T O S T R I N G;
K_DESCEND : D E S C E N D;
K_DOUBLE : D O U B L E;
K_DAY : D A Y;
K_DISABLE : D I S A B L E;
K_DROP : D R O P;
K_DEFAULT : D E F A U L T;
K_DISALLOW : D I S A L L O W;
K_DROP_FTINDEX : D R O P UNDERSCORE F T I N D E X;
K_DELETE : D E L E T E;
K_DISPLAY : D I S P L A Y;
K_ELSE : E L S E;
K_ENFORCE : E N F O R C E;
K_EXEC : E X E C;
K_ELSEIF : E L S E I F;
K_ESCAPE : E S C A P E;
K_EXECUTE : E X E C U T E;
K_ENABLE : E N A B L E;
K_ESTIMATE : E S T I M A T E;
K_EXISTS : E X I S T S;
K_FALSE : F A L S E;
K_FOR : F O R;
K_FT_OPTIMIZER : F T UNDERSCORE O P T I M I Z E R;
K_FIRST : F I R S T;
K_FOREIGN : F O R E I G N;
K_FULLTEXT : F U L L T E X T;
K_FLOAT : F L O A T;
K_FROM : F R O M;
K_FUNCTION : F U N C T I O N;
K_FOLDER : F O L D E R;
K_FTINDEX : F T I N D E X;
K_GRANT : G R A N T;
K_GROUP : G R O U P;
K_HAVING : H A V I N G;
K_HITS : H I T S;
K_ID : I D;
K_INT : I N T;
K_IS : I S;
K_IF : I F;
K_INTEGER : I N T E G E R;
K_ISCURRENT : I S C U R R E N T;
K_IN : I N;
K_INTERNAL : I N T E R N A L;
K_ISPUBLIC : I S P U B L I C;
K_INSERT : I N S E R T;
K_INTO : I N T O;
K_ISREPLICA : I S R E P L I C A;
K_JOIN : J O I N;
K_KEY : K E Y;
K_LANGUAGE : L A N G U A G E;
K_LIGHTWEIGHT : L I G H T W E I G H T;
K_LITE : L I T E;
K_LAST : L A S T;
K_LIKE : L I K E;
K_LOWER : L O W E R;
K_LATEST : L A T E S T;
K_LINK : L I N K;
K_LEFT : L E F T;
K_LIST : L I S T;
K_MAPPING : M A P P I N G;
K_MEMBERS : M E M B E R S;
K_MONTH : M O N T H;
K_MATERIALIZE : M A T E R I A L I Z E;
K_MFILE_URL : M F I L E UNDERSCORE U R L;
K_MOVE : M O V E;
K_MATERIALIZATION : M A T E R I A L I Z A T I O N;
K_MHITS : M H I T S;
K_MSCORE : M S C O R E;
K_MAX : M A X;
K_MIN : M I N;
K_MCONTENTID : M C O N T E N T I D;
K_MODIFY : M O D I F Y;
K_NODE : N O D E;
K_NOTE : N O T E;
K_NULLID : N U L L I D;
K_NODESORT : N O D E S O R T;
K_NOW : N O W;
K_NULLINT : N U L L I N T;
K_NONE : N O N E;
K_NULL : N U L L;
K_NULLSTRING : N U L L S T R I N G;
K_NOT : N O T;
K_NULLDATE : N U L L D A T E;
K_OF : O F;
K_ON : O N;
K_ORDER : O R D E R;
K_OBJECT : O B J E C T;
K_ONLY : O N L Y;
K_OUTER : O U T E R;
K_OBJECTS : O B J E C T S;
K_OR : O R;
K_OWNER : O W N E R;
K_PAGE_NO : P A G E UNDERSCORE N O;
K_PERMIT : P E R M I T;
K_PRIVATE : P R I V A T E;
K_PARENT : P A R E N T;
K_POLICY : P O L I C Y;
K_PRIVILEGES : P R I V I L E G E S;
K_PARTITIONABLE : P A R T I T I O N A B L E;
K_PARTITION : P A R T I T I O N;
K_POSITION : P O S I T I O N;
K_PROPERTY : P R O P E R T Y;
K_PATH : P A T H;
K_PRIMARY : P R I M A R Y;
K_PUBLIC : P U B L I C;
K_PUBLISH : P U B L I S H;
K_PURGE : P U R G E;
K_QRY : Q R Y;
K_QUALIFIABLE : Q U A L I F I A B L E;
K_RDBMS : R D B M S;
K_RELATE : R E L A T E;
K_REPORT : R E P O R T;
K_READ : R E A D;
K_REMOVE : R E M O V E;
K_REQUEST : R E Q U E S T;
K_REFERENCES : R E F E R E N C E S;
K_REPEATING : R E P E A T I N G;
K_REVOKE : R E V O K E;
K_REGISTER : R E G I S T E R;
K_REPLACEIF : R E P L A C E I F;
K_SHAREABLE : S H A R E A B L E;
K_SCORE : S C O R E;
K_SMALLINT : S M A L L I N T;
K_SUPERTYPE : S U P E R T Y P E;
K_SEARCH : S E A R C H;
K_SOME : S O M E;
K_SUPERUSER : S U P E R U S E R;
K_SELECT : S E L E C T;
K_STATE : S T A T E;
K_SUPPORT : S U P P O R T;
K_SEPARATOR : S E P A R A T O R;
K_SPACEOPTIMIZE: S P A C E O P T I M I Z E;
K_STORAGE : S T O R A G E;
K_SYNONYM : S Y N O N Y M;
K_SERVER : S E R V E R;
K_STRING : S T R I N G;
K_SYSADMIN : S Y S A D M I N;
K_SET : S E T;
K_SUBSTR : S U B S T R;
K_SYSOBJ_ID : S Y S O B J UNDERSCORE I D;
K_SETFILE : S E T F I L E;
K_SUBSTRING : S U B S T R I N G;
K_SYSTEM : S Y S T E M;
K_SUM : S U M;
K_SHARES : S H A R E S;
K_SUMMARY : S U M M A R Y;
K_TABLE : T A B L E;
K_TO : T O;
K_TRANSACTION : T R A N S A C T I O N;
K_TAG : T A G;
K_TODAY : T O D A Y;
K_TRUE : T R U E;
K_TEXT : T E X T;
K_TOMORROW : T O M O R R O W;
K_TRUNCATE : T R U N C A T E;
K_TIME : T I M E;
K_TOPIC : T O P I C;
K_TYPE : T Y P E;
K_TINYINT : T I N Y I N T;
K_TRAN : T R A N;
K_UNION : U N I O N;
K_UNREGISTER : U N R E G I S T E R;
K_UPDATE : U P D A T E;
K_UNIQUE : U N I Q U E;
K_USER : U S E R;
K_UPPER : U P P E R;
K_UNLINK : U N L I N K;
K_USING : U S I N G;
K_VALUE : V A L U E;
K_VERSION : V E R S I O N;
K_VIEW : V I E W;
K_VIOLATION : V I O L A T I O N;
K_VALUES : V A L U E S;
K_VERITY : V E R I T Y;
K_WHERE : W H E R E;
K_WITHOUT : W I T H O U T;
K_WEEK : W E E K;
K_WITH : W I T H;
K_WORLD : W O R L D;
K_WITHIN : W I T H I N;
K_WRITE : W R I T E;
K_YEAR : Y E A R;
K_YESTERDAY : Y E S T E R D A Y;

IDENTIFIER
 : '"' (~'"' | '""')* '"'
 | [a-zA-Z_] [a-zA-Z_0-9]* 
 ;

SPACES
 : [ \u000B\t\r\n] -> channel(HIDDEN)
 ;

UNEXPECTED_CHAR
 : .
 ;
 
 
fragment DIGIT : [0-9];
fragment A : ('a'|'A');
fragment B : ('b'|'B');
fragment C : ('c'|'C');
fragment D : ('d'|'D');
fragment E : ('e'|'E');
fragment F : ('f'|'F');
fragment G : ('g'|'G');
fragment H : ('h'|'H');
fragment I : ('i'|'I');
fragment J : ('j'|'J');
fragment K : ('k'|'K');
fragment L : ('l'|'L');
fragment M : ('m'|'M');
fragment N : ('n'|'N');
fragment O : ('o'|'O');
fragment P : ('p'|'P');
fragment Q : ('q'|'Q');
fragment R : ('r'|'R');
fragment S : ('s'|'S');
fragment T : ('t'|'T');
fragment U : ('u'|'U');
fragment V : ('v'|'V');
fragment W : ('w'|'W');
fragment X : ('x'|'X');
fragment Y : ('y'|'Y');
fragment Z : ('z'|'Z');
fragment UNDERSCORE : '_';

