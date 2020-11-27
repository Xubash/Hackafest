--------------------------------------------------------------------------------
--View running queries detail
SELECT 
SUBSTR(SS.USERNAME,1,8) USERNAME,
SS.OSUSER "USER",
AR.MODULE || ' @ ' || SS.machine CLIENT,
SS.PROCESS PID,
TO_CHAR(AR.LAST_LOAD_TIME, 'DD-Mon HH24:MM:SS') LOAD_TIME,
AR.DISK_READS DISK_READS,
AR.BUFFER_GETS BUFFER_GETS,
SUBSTR(SS.LOCKWAIT,1,10) LOCKWAIT,
W.EVENT EVENT,
SS.status,
AR.SQL_fullTEXT SQL
FROM V$SESSION_WAIT W,
V$SQLAREA AR,
V$SESSION SS, 
v$timer T
WHERE SS.SQL_ADDRESS = AR.ADDRESS
AND SS.SQL_HASH_VALUE = AR.HASH_VALUE
AND SS.SID = w.SID (+)
AND ss.STATUS = 'ACTIVE'
AND W.EVENT != 'client message'
AND USERNAME = USER 
ORDER BY  SS.LOCKWAIT ASC, SS.USERNAME, AR.DISK_READS DESC
;
--------------------------------------------------------------------------------
SELECT * FROM V$SESSION_LONGOPS WHERE TIME_REMAINING<> 0 AND TARGET LIKE '%WH0718001%';   
SELECT TARGET,TOTALWORK, UNITS, START_TIME,LAST_UPDATE_TIME,TIME_REMAINING, ELAPSED_SECONDS ,MESSAGE FROM V$SESSION_LONGOPS WHERE TIME_REMAINING<> 0 AND TARGET LIKE '%VC0300XXXTEST04%';   


SELECT 'ALTER SYSTEM KILL SESSION '''||SID||', '||SERIAL#||''' IMMEDIATE;' QUERY,A.* FROM V$SESSION A WHERE USERNAME = 'SYSTEM' ORDER BY STATUS 

--WHERE UPPER(OSUSER) IN ('I97155','I97156')

--To kill specific sessions
SELECT 'ALTER SYSTEM KILL SESSION '''||SID||', '||SERIAL#||''' IMMEDIATE;' QUERY FROM v$session a WHERE EXISTS (SELECT 1 FROM V$SQLAREA b WHERE b.SQL_FULLTEXT  LIKE '%3927%' AND a.SQL_ADDRESS = b.ADDRESS) AND OSUSER = 'i10437'

--------------------------------------------------------------------------------
--Locked session
--Setp 1
select ORACLE_USERNAME, OS_USER_NAME, object_name, s.sid, s.serial#, p.spid 
from v$locked_object l, dba_objects o, v$session s, v$process p
where l.object_id = o.object_id and l.session_id = s.sid and s.paddr = p.addr;
--SS_MED_1215	113	131	24385

--step 2:
ALTER SYSTEM KILL SESSION '113, 131';
--SID` AND `SERIAL#` GET FROM STEP 1
--------------------------------------------------------------------------------
--More detail
SELECT O.OBJECT_NAME, S.SID, S.SERIAL#, P.SPID, S.PROGRAM,S.USERNAME,
S.MACHINE,S.PORT , S.LOGON_TIME,SQ.SQL_FULLTEXT 
FROM V$LOCKED_OBJECT L, DBA_OBJECTS O, V$SESSION S, 
V$PROCESS P, V$SQL SQ 
WHERE L.OBJECT_ID = O.OBJECT_ID 
AND L.SESSION_ID = S.SID AND S.PADDR = P.ADDR 
AND S.SQL_ADDRESS = SQ.ADDRESS;
--------------------------------------------------------------------------------

SELECT OSUSER, MACHINE,	PROGRAM, SCHEMANAME,  TYPE,STATUS, COUNT(DISTINCT SQL_ID) FROM V$SESSION GROUP BY OSUSER, MACHINE,	PROGRAM, SCHEMANAME,  TYPE,STATUS ORDER BY OSUSER, MACHINE,	PROGRAM, SCHEMANAME,  TYPE,STATUS;


--------------------------------------------------------------------------------
--Row level lock, enq: TX - row lock contention
--------------------------------------------------------------------------------
--To find for which SQL is currently waiting on:
SELECT 
	s.SID,
	q.sql_Text
FROM
	v$session s,
	v$sql q
WHERE
	SID IN (SELECT SID FROM v$session WHERE STate IN ('WAITING') AND wait_Class != 'Idle' AND event='enq: TX - row lock contention')
	AND (q.sql_id = s.Sql_ID OR q.SQL_ID = s.prev_sql_id)
;
--------------------------------------------------------------------------------
--The blocking session is
--------------------------------------------------------------------------------
SELECT 
	blocking_Session, SID, Serial#, Wait_Class, seconds_In_Wait
FROM
	v$session
WHERE
	blocking_Session IS NOT NULL
ORDER BY
	blocking_session
;
--------------------------------------------------------------------------------