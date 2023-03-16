alter session set timestamp_output_format = 'YYYY-MM-DD HH24:MI:SS TZHTZM';

set StartTimeRange = '2022-1-31 18:00:00';
set EndTimeRange = '2022-2-1 17:00:00';


with MachineMinMaxBootTimes as (

  SELECT
    MID MID
    ,MIN(LAST_BOOT_TIME) MIN_BOOT_TIME
    ,MAX(LAST_BOOT_TIME) MAX_BOOT_TIME

  FROM PRODN_CDB_MARQETA_B02BDD2B0E6E948C2AD9837A6F6B9C720D14D98F2DCC5AB5.PUBLIC.MACHINE_DETAILS_T
  WHERE CREATED_TIME BETWEEN DATEADD(HOUR,-24,TO_TIMESTAMP($StartTimeRange)) AND TO_TIMESTAMP($EndTimeRange)
  GROUP BY 1

)

, MB AS (

  select
    mid
    ,MAX_BOOT_TIME
  from MachineMinMaxBootTimes

)

, HostVuln_SummaryViewWithFilter as (

   SELECT
        START_TIME,
        END_TIME,
        EVAL_GUID,
        EVAL_CTX:hostname::VARCHAR HOSTNAME
        ,MID
        ,MACHINE_TAGS
        ,SUMMARY

    FROM PRODN_CDB_MARQETA_B02BDD2B0E6E948C2AD9837A6F6B9C720D14D98F2DCC5AB5.VULN_INTERNAL.HOST_VULN_EVAL_SUMMARY_T
    WHERE START_TIME >= to_timestamp($StartTimeRange)
    AND END_TIME <= to_timestamp($EndTimeRange)

)

, HostVuln_LastEvalGUIDByMachine as (

    SELECT MID, EVAL_GUID
    FROM (
        SELECT MID, EVAL_GUID, COALESCE(SUMMARY:isDailyJob::INT, 0) IS_DAILY,
        ROW_NUMBER() OVER (PARTITION BY MID ORDER BY IS_DAILY DESC) RN
        FROM HostVuln_SummaryViewWithFilter
        WHERE (MID, START_TIME) IN (
            SELECT MID, MAX(START_TIME) FROM HostVuln_SummaryViewWithFilter
            GROUP BY 1
        )
    )
    WHERE RN = 1

)

,  HostVuln_LastEvalDetailsByMachine as (

    SELECT
        START_TIME,
        VULN_ID,
        MID,
        MACHINE_TAGS,
        EVAL_CTX:hostname::VARCHAR HOSTNAME,
        TO_TIMESTAMP(PROPS:last_updated_time) LAST_UPDATED_TIME,
        TO_TIMESTAMP(PROPS:first_time_seen) FIRST_SEEN_TIME,
        FEATURE_KEY:namespace::VARCHAR PACKAGE_NAMESPACE,
        FEATURE_KEY:name::VARCHAR PACKAGE,
        case when SEVERITY IN ('Critical', 'High', 'Medium', 'Low') then SEVERITY else 'Info' end SEVERITY,
        FIX_INFO:fix_available FIX_AVAILABLE,
        FIX_INFO:fixed_version::VARCHAR FIXED_VERSION,
        FIX_INFO:version_installed::VARCHAR VERSION_INSTALLED,
        FIX_VERSIONS_INSTALLED,
        FIX_INFO:eval_status::VARCHAR EVAL_STATUS,
        STATUS,
        COALESCE(PROPS:pkgVerExists::INT, 1) PKG_EXISTS,
        CVE_PROPS

    FROM PRODN_CDB_MARQETA_B02BDD2B0E6E948C2AD9837A6F6B9C720D14D98F2DCC5AB5.VULN_INTERNAL.HOST_VULN_EVAL_DETAILS_T D
    WHERE D.START_TIME >= to_timestamp($StartTimeRange)
    AND D.END_TIME <= to_timestamp($EndTimeRange)
    AND (D.MID, D.EVAL_GUID) IN (SELECT MID, EVAL_GUID FROM HostVuln_LastEvalGUIDByMachine)

)

, HostVuln_ActPkg as (

    SELECT DISTINCT
        FIM.start_time
        ,mid
        ,path
        ,activity
        ,props: last_package_name::VARCHAR pkg_name
        ,props: last_version::VARCHAR pkg_version
        ,'ACTIVE' package_status

      FROM PRODN_CDB_MARQETA_B02BDD2B0E6E948C2AD9837A6F6B9C720D14D98F2DCC5AB5.mview_internal.FILE_MVIEW_ACT_T FIM
      WHERE FIM.start_time <= to_timestamp($EndTimeRange)
      AND FIM.start_time >= DATEADD('hour', -24, to_timestamp($EndTimeRange) )
      AND props: last_package_name::VARCHAR <> ''
      AND activity IN ('New', 'Active')

)

//select * from HostVuln_ActPkg;

, HostVuln_LastEvalDetailsByMachineWithHostType as (

 WITH current_hour_mids AS (
        select distinct mid
        from PRODN_CDB_MARQETA_B02BDD2B0E6E948C2AD9837A6F6B9C720D14D98F2DCC5AB5.public.process_stats_t
        where created_time >= dateadd(hour, -1, current_timestamp())
      )
      SELECT t1.*
        ,case when t2.mid is not null then 'Online' else 'Offline' end HOST_TYPE
      FROM HostVuln_LastEvalDetailsByMachine t1
      LEFT JOIN current_hour_mids t2
      ON t1.mid = t2.mid

)

//select * from HostVuln_LastEvalDetailsByMachineWithHostType;

, HostVuln_LastEvalDetailsByMachineWithHostTypePkgStat as (

    SELECT Details.*
        ,ActPkg.package_status
      FROM HostVuln_LastEvalDetailsByMachineWithHostType Details
        LEFT JOIN HostVuln_ActPkg ActPkg
        ON  Details.MID = ActPkg.mid
        AND Details.PACKAGE = ActPkg.pkg_name
        AND Details.VERSION_INSTALLED = ActPkg.pkg_version

)

//select * from HostVuln_LastEvalDetailsByMachineWithHostTypePkgStat;

, output as (

select distinct
    t.hostname
    ,t.vuln_id
    ,t.cve_props:description::string as cve_description
    ,t.severity
    ,t.status
    ,t.machine_tags:VmProvider::string as VmProvider
    ,t.machine_tags:Account::string as account_id
    ,t.machine_tags:AmiId::string as ami_id
    ,t.mid
    ,t.host_type

    ,datediff(min, MB.MAX_BOOT_TIME, current_timestamp()) UP_TIME_MINS

    ,coalesce(t.machine_tags:InternalIp::string,'') as InternalIp
    ,coalesce(t.machine_tags:ExternalIp::string,'') as ExternalIp

    ,case t.fix_available::int
        when 1 then 'Yes'
        when 0 then 'No'
        else ''
    end as fix_available

    ,t.package_namespace
    ,t.package

    ,t.fixed_version as fix_version
    ,t.version_installed

from HostVuln_LastEvalDetailsByMachineWithHostTypePkgStat as t

left join MB
    on t.mid = MB.mid

where true
    and fix_available::int = 1
    and status not in ('Unknown','FixedOnDiscovery','Fixed')
    and status is not null
    and severity in ('Critical', 'High')
    and severity is not null
)

select * from output
    WHERE (MID) IN (
        SELECT DISTINCT MID FROM output
           where severity in ('Critical')
      )
;