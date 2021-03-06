﻿-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

WITH present as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.AttendanceEventCategoryDescriptor ON
				Descriptor.DescriptorId = AttendanceEventCategoryDescriptor.AttendanceEventCategoryDescriptorId
		WHERE
			Descriptor.CodeValue = 'In Attendance'
	) as d
	WHERE DescriptorConstant.ConstantName = 'AttendanceEvent.Present'
), excusedAbsence as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.AttendanceEventCategoryDescriptor ON
				Descriptor.DescriptorId = AttendanceEventCategoryDescriptor.AttendanceEventCategoryDescriptorId
		WHERE
			Descriptor.CodeValue = 'Excused Absence'
	) as d
	WHERE DescriptorConstant.ConstantName = 'AttendanceEvent.ExcusedAbsence'
), unexcusedAbsence as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.AttendanceEventCategoryDescriptor ON
				Descriptor.DescriptorId = AttendanceEventCategoryDescriptor.AttendanceEventCategoryDescriptorId
		WHERE
			Descriptor.CodeValue = 'Unexcused Absence'
	) as d
	WHERE DescriptorConstant.ConstantName = 'AttendanceEvent.UnexcusedAbsence'
), tardy as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.AttendanceEventCategoryDescriptor ON
				Descriptor.DescriptorId = AttendanceEventCategoryDescriptor.AttendanceEventCategoryDescriptorId
		WHERE
			Descriptor.CodeValue = 'Tardy'
	) as d
	WHERE DescriptorConstant.ConstantName = 'AttendanceEvent.Tardy'
), instructionalDay as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.CalendarEventDescriptor ON
				Descriptor.DescriptorId = CalendarEventDescriptor.CalendarEventDescriptorId
		WHERE
			Descriptor.CodeValue IN ('Instructional Day', 'Make-up day')
	) as d
	WHERE DescriptorConstant.ConstantName = 'CalendarEvent.InstructionalDay'
), stateOffenses as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.BehaviorDescriptor ON
				Descriptor.DescriptorId = BehaviorDescriptor.BehaviorDescriptorId
		INNER JOIN
			edfi.BehaviorType ON
				BehaviorDescriptor.BehaviorTypeId = BehaviorType.BehaviorTypeId
		WHERE
			BehaviorType.CodeValue = 'State Offense'
	) as d
	WHERE DescriptorConstant.ConstantName = 'Behavior.StateOffense'
), schoolOffenses as (
	SELECT 
		DescriptorConstant.DescriptorConstantId,
		d.DescriptorId
	FROM 
		analytics_config.DescriptorConstant
	CROSS JOIN (
		SELECT 
			Descriptor.DescriptorId
		FROM
			edfi.Descriptor
		INNER JOIN
			edfi.BehaviorDescriptor ON
				Descriptor.DescriptorId = BehaviorDescriptor.BehaviorDescriptorId
		INNER JOIN
			edfi.BehaviorType ON
				BehaviorDescriptor.BehaviorTypeId = BehaviorType.BehaviorTypeId
		WHERE
			BehaviorType.CodeValue IN ('School Code of Conduct')
	) as d
	WHERE DescriptorConstant.ConstantName = 'Behavior.SchoolCodeOfConductOffense'
)
MERGE INTO analytics_config.DescriptorMap AS Target
USING (
	SELECT * FROM present
	UNION ALL
	SELECT * FROM excusedAbsence
	UNION ALL
	SELECT * FROM unexcusedAbsence
	UNION ALL
	SELECT * FROM tardy
	UNION ALL
	SELECT * FROM instructionalDay
	UNION ALL
	SELECT * FROM stateOffenses
	UNION ALL
	SELECT * FROM schoolOffenses
) AS Source(DescriptorConstantId, DescriptorId)
ON TARGET.DescriptorConstantId = Source.DescriptorConstantId
    WHEN NOT MATCHED BY TARGET
    THEN
      INSERT
	  (
		DescriptorConstantId, 
		DescriptorId, 
		CreateDate
	  )
      VALUES
      (
        Source.DescriptorConstantId,
        Source.DescriptorId,
        getdate()
      )
OUTPUT $action,
       inserted.*;
