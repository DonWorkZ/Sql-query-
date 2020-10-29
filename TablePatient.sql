 WITH TablePatient AS
(
SELECT
case
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=0 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 4 then 'number of cases from 0-4 yrs old'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=5 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 24 then 'number of cases from 5-24 yrs old'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=25 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 49 then 'number of cases from 25-49 yrs old'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=50-64 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 4 then 'number of cases from 50-64 yrs old'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=65 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 4 then 'number of cases from 65 and up'
end
as Age_Bracket,
Count([tblPatient].[PatientNumber]) as [Count_tblPatient.PatientNumber]
FROM
PncRegDb.dbo.[tblVisitDiagnosis] as [tblVisitDiagnosis] WITH (NOLOCK)
LEFT JOIN PncRegDb.dbo.[tblPatient] as [tblPatient] WITH (NOLOCK)
on ([tblVisitDiagnosis].[PatientID]=[tblPatient].[PatientID])
LEFT JOIN PncRegDb.dbo.[tblVisit] as [tblVisit] WITH (NOLOCK)
on ([tblVisitDiagnosis].[VisitId]=[tblVisit].[VisitId])
LEFT JOIN PncRegDb.dbo.[ctblFacility] as [ctblFacility] WITH (NOLOCK)
on ([tblVisit].[VisitFacilityID]=[ctblFacility].[FacilityId])
LEFT JOIN PncRegDb.dbo.[ctblDiagnosis] as [ctblDiagnosis] WITH (NOLOCK)
on ([tblVisitDiagnosis].[DiagnosisId]=[ctblDiagnosis].[DiagnosisId])
WHERE
(DateDiff(ww, tblVisit.VisitDate, GetDate()) = 1
AND [ctblFacility].[FacilityId]  IN (1, 6)
AND ([tblVisitDiagnosis].[ICDCode] like '%487.1%'
OR [tblVisitDiagnosis].[ICDCode] like 'J11%'
OR [tblVisitDiagnosis].[ICDCode] like 'J10%'
OR [tblVisitDiagnosis].[ICDCode] like 'J09%'
OR ([tblVisitDiagnosis].[ICDCode] like 'r69%'
AND [ctblDiagnosis].[DiagnosisText] like '%influenza%')))
AND [tblVisitDiagnosis].[DeletedDateTime] is null
AND COALESCE([tblPatient].[isTestPatient],0) = 0
AND [tblVisit].[DeletedDateTime] is null
AND (Coalesce([tblVisit].[SecurityDivisionBitCode],0xFFFFFFFF) & 31)<>0
GROUP BY
case
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=0 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 4 then '0-4'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=5 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 24 then '5-24'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=25 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 49 then '25-49'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=50-64 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 4 then '50-64'
when
PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) >=65 and PncRegDB.dbo.fnOpenReport_Age([tblPatient].[PatientDOB],[tblVisitDiagnosis].[VisitDate]) <= 4 then '65+'
end
)
Select distinct concat('57203',',',a.[Age Bracket],',',
a.[Count_tblPatient.PatientNumber],',',
' total visits ',b.[Count_tblPatient.PatientNumber])
(SELECT distinct STUFF((
       SELECT ',' + t1.Age_Bracket
         FROM TablePatient t2
        ORDER BY t2.Age_Bracket
          FOR XML PATH('')), 1, LEN(','), '') AS Age_Bracket,
		  STUFF((
       SELECT ',' + t1.[Count_tblPatient.PatientNumber]
         FROM TablePatient t2
        ORDER BY t2.Age_Bracket
          FOR XML PATH('')), 1, LEN(','), '') AS [Count_tblPatient.PatientNumber]
  FROM TablePatient t1) a,  
(
 SELECT
-Grouping(DateDiff(ww, Appointment.AppointmentDateTime, GetDate())) as [-Grouping_DateDiff],
0 as [X.rollup],
DateDiff(ww, Appointment.AppointmentDateTime, GetDate()) as [DateDiff],
Count([tblPatient].[PatientNumber]) as [Count_tblPatient.PatientNumber]
FROM
PncRegDb.dbo.[tblAppointment] as [Appointment] WITH (NOLOCK)
LEFT JOIN PncRegDb.dbo.[tblProvider] as [tblProvider] WITH (NOLOCK)
on ([Appointment].[ProviderID]=[tblProvider].[ProviderID])
LEFT JOIN PncRegDb.dbo.[ctblProviderType] as [ctblProviderType] WITH (NOLOCK)
on ([tblProvider].[ProviderTypeID]=[ctblProviderType].[ProviderTypeID])
LEFT JOIN PncRegDb.dbo.[ctblLocation] as [ctblLocation] WITH (NOLOCK)
on ([Appointment].[LocationID]=[ctblLocation].[LocationID])
LEFT JOIN PncRegDb.dbo.[ctblFacility] as [ctblFacility] WITH (NOLOCK)
on ([ctblLocation].[FacilityID]=[ctblFacility].[FacilityId])
LEFT JOIN PncRegDb.dbo.[ctblVisitType] as [ctblVisitType] WITH (NOLOCK)
on ([Appointment].[VisitTypeID]=[ctblVisitType].[VisitTypeID])
LEFT JOIN PncRegDb.dbo.[tblPatient] as [tblPatient] WITH (NOLOCK)
on ([Appointment].[PatientID]=[tblPatient].[PatientID])
LEFT JOIN PncRegDb.dbo.[tblAppointmentPatient] as [tblAppointmentPatient] WITH (NOLOCK)
on ([Appointment].[AppointmentID]=[tblAppointmentPatient].[AppointmentID])
WHERE
(CASE WHEN appointment.canceldatetime is null
and ctblvisittype.patientvisit = 1
and appointment.lefttime is null
and (appointment.checkintime is not null or tblAppointmentPatient.ParticipantStatus = 'A')
then 1
else 0
end = 1
AND DateDiff(ww, Appointment.AppointmentDateTime, GetDate()) = 1
AND [Appointment].[SecurityDivisionBitCode] = 1
AND ([tblProvider].[ProviderName] = 'WE WAITING ROOM' /* WE WAITING ROOM */
OR [tblProvider].[ProviderName] = 'WE WAITING ROOM - BROOKLYN' /* WE WAITING ROOM - BROOKLYN */
OR [tblProvider].[ProviderName] = 'WE WAITING ROOM - WSQ' /* WE WAITING ROOM - WSQ */
OR [tblProvider].[ProviderName] = 'WH WAITING ROOM' /* WH WAITING ROOM */
OR [tblProvider].[ProviderName] = 'URGENT CARE' /* URGENT CARE */
OR [tblProvider].[ProviderName] = 'TRIAGE ROOM' /* TRIAGE ROOM */
OR [tblProvider].[ProviderName] = 'PC3 WAITING' /* PC3 WAITING */
OR [tblProvider].[ProviderName] = 'RADIOLOGY'
OR [ctblProviderType].[ProviderTypeName]  NOT IN ('ROOM', 'WAITINGROOM')
OR [ctblProviderType].[ProviderTypeName] is null )
AND [ctblFacility].[FacilityId]  IN (1, 6))
AND (Coalesce([Appointment].[SecurityDivisionBitCode],0xFFFFFFFF) & 31)<>0
AND COALESCE([tblProvider].[TestProvider],0) = 0
AND COALESCE([tblPatient].[isTestPatient],0) = 0
GROUP BY
DateDiff(ww, Appointment.AppointmentDateTime, GetDate())
WITH ROLLUP
)b;