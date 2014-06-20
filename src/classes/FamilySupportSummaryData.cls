public with sharing class FamilySupportSummaryData extends MonthSummaryData
{
	private Set<ID>clientsWithReferralsOutSupportedThisMonth=new Set<ID>();
	private Set<ID>newclientsThisMonth=new Set<ID>();
	private Set<ID>clientsOneToOneSupportThisMonth=new Set<ID>();
	
	Date endOfMonthPlus1;
	
	public FamilySupportSummaryData (Date eom, Set<ID> familySupportClients)
	{
		super(eom);
		endOfMonthPlus1 = endOfMonth.addDays(1);
		for (Event oneEvent: [select WhoID, None__c, Days_since_last_activity__c, Type_of_event__c, StartDateTime from Event where StartDateTime >= :caseLoadStart and StartDateTime < :endOfMonthPlus1 and WhoID in :familySupportClients])
		{
			caseLoadClients.add(oneEvent.WhoID);
			if (oneEvent.StartDateTime >= startOfMonth) 
			{
				clientsSupportedThisMonth.add(oneEvent.WhoID);
				if (!oneEvent.None__c) clientsWithReferralsOutSupportedThisMonth.add(oneEvent.WhoID);
				if (oneEvent.Days_since_last_activity__c==null || oneEvent.Days_since_last_activity__c>60) newclientsThisMonth.add(oneEvent.WhoID);
				if (oneEvent.Type_of_event__c == 'One to one support') clientsOneToOneSupportThisMonth.add (oneEvent.WhoID);
			}
		}
		
		countIndividualsInFamilySupportGroups ();
		countNewAttendees();
		countTotalAndAge();		
		countClientTypes();
		countOne2OneSupport();
		countOne2OneSupportClients();
		countOne2OneSupportTypeGiven();
		countphoneSupportGiven();
		countFamilySupportSessions();
		countReferralsIn ();
		countReferralsOutTotals ();
		countReferralsOutAndAdvocacy ();
		countFamilySupportGroups ();
		countNewFamilySupportGroups ();
	}
	
	public override void countNewAttendees ()
	{
		List<aggregateResult> results = [select Region__c, Gender__c, count(ID) gender from Contact where ID in :newclientsThisMonth group by Region__c, Gender__c];
		for (aggregateResult ar : results)
		{
			if ((String)ar.get('Gender__c') == 'Male')
			{
				if ((String)ar.get('Region__c') == 'Longford') 
					Region1.newMales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Westmeath') 
					Region2.newMales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Laois') 
					Region3.newMales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Offaly') 
					Region4.newMales = (Integer)ar.get('gender');
			}
			else
			{
				if ((String)ar.get('Region__c') == 'Longford') 
					Region1.newFemales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Westmeath') 
					Region2.newFemales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Laois') 
					Region3.newFemales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Offaly') 
					Region4.newFemales = (Integer)ar.get('gender');
			}
		}			
		Region1.newAttendees = Region1.newMales + Region1.newFemales;
		Region2.newAttendees = Region2.newMales + Region2.newFemales;
		Region3.newAttendees = Region3.newMales + Region3.newFemales;
		Region4.newAttendees = Region4.newMales + Region4.newFemales;
	}
	
	public override void countTotalAndAge ()
	{
		List<Contact> clients = [select ID, Gender__c, Age__c, Region__c
			from Contact where id in :caseLoadClients];
		for (Contact oneClient: clients)
		{
			if (oneClient.Region__c == 'Longford')
			{
				incrementGenderTotalInRegion (Region1, oneClient);
				incrementAgeTotalInRegion (Region1, oneClient);
			}
			else if (oneClient.Region__c == 'Westmeath')
			{
				incrementGenderTotalInRegion (Region2, oneClient);
				incrementAgeTotalInRegion (Region2, oneClient);
			}
			else if (oneClient.Region__c == 'Laois')
			{
				incrementGenderTotalInRegion (Region3, oneClient);
				incrementAgeTotalInRegion (Region3, oneClient);
			}
			else if (oneClient.Region__c == 'Offaly')
			{
				incrementGenderTotalInRegion (Region4, oneClient);
				incrementAgeTotalInRegion (Region4, oneClient);
			}
		}
	}
	
	public override void countClientTypes()
	{
		List<aggregateResult> results = [select Region__c, Type_of_client__c, count(ID) typeClient from Contact where id in :caseLoadClients group by Region__c, Type_of_client__c];
		for (aggregateResult ar : results)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
		}
	}

	public void countFamilySupportSessions()
	{
		List<aggregateResult> supportResults = [select Region__c, count(ID) support from Event where StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth and Type_of_event__c = 'Family support session' group by Region__c];
		for (aggregateResult ar : supportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.FamilySupportSessions += (Integer)ar.get('support');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.FamilySupportSessions += (Integer)ar.get('support');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.FamilySupportSessions += (Integer)ar.get('support');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.FamilySupportSessions += (Integer)ar.get('support');
			}
		}
	}

	public override void countPrimaryDrugs()
	{
	}
	
	public override void countReferralsIn ()
	{
		Date endMonthplus1 = endOfMonth.addDays(1);
		List<aggregateResult> referralResults = [select Region__c, Source_of_referral__c, count(ID) referral
			from Contact where id in :clientsSupportedThisMonth and CreatedDate >= :startOfMonth and CreatedDate < :endMonthplus1 group by Region__c, Source_of_referral__c];
		system.debug ('Number of clients supported: ' + clientsSupportedThisMonth.size());
		system.debug ('start of month ' + startOfMonth + ' end of month ' + endMonthplus1);
		system.debug ('Number of referrals in: ' + referralResults.size());
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.referralsIn.put ((String)ar.get('Source_of_referral__c'), (Integer)ar.get('referral'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.referralsIn.put ((String)ar.get('Source_of_referral__c'), (Integer)ar.get('referral'));
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.referralsIn.put ((String)ar.get('Source_of_referral__c'), (Integer)ar.get('referral'));
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.referralsIn.put ((String)ar.get('Source_of_referral__c'), (Integer)ar.get('referral'));
		}

		referralResults = [select Region__c, Gender__c, count(ID) gender
			from Contact where id in :clientsSupportedThisMonth and CreatedDate >= :startOfMonth and CreatedDate < :endMonthplus1 group by Region__c, Gender__c];
		system.debug ('Number of referrals with gender: ' + referralResults.size());
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region1.maleReferralsIn = (Integer)ar.get('gender');
				else Region1.femaleReferralsIn = (Integer)ar.get('gender');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region2.maleReferralsIn = (Integer)ar.get('gender');
				else Region2.femaleReferralsIn = (Integer)ar.get('gender');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region3.maleReferralsIn = (Integer)ar.get('gender');
				else Region3.femaleReferralsIn = (Integer)ar.get('gender');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region4.maleReferralsIn = (Integer)ar.get('gender');
				else Region4.femaleReferralsIn = (Integer)ar.get('gender');
			}
		}
		Region1.totalReferralsIn = Region1.maleReferralsIn + Region1.femaleReferralsIn;
		Region2.totalReferralsIn = Region2.maleReferralsIn + Region2.femaleReferralsIn;
		Region3.totalReferralsIn = Region3.maleReferralsIn + Region3.femaleReferralsIn;
		Region4.totalReferralsIn = Region4.maleReferralsIn + Region4.femaleReferralsIn;
	}
	
	public void countOne2OneSupport()
	{
		List<aggregateResult> supportResults = [select Region__c, Reason_for_support__c, count(ID) support from Event where WhoID in (select ID from Contact where ID in :clientsSupportedThisMonth) and StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth and Type_of_event__c = 'One to one support' group by Region__c, Reason_for_support__c];
		for (aggregateResult ar : supportResults)
		{
			String supportName = (String)ar.get('Reason_for_support__c');
			if (supportName == null) supportName = 'Not specified';
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.one2one += (Integer)ar.get('support');
				Region1.supports.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.one2one += (Integer)ar.get('support');
				Region2.supports.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.one2one += (Integer)ar.get('support');
				Region3.supports.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.one2one += (Integer)ar.get('support');
				Region4.supports.put(supportName, (Integer)ar.get('support'));
			}
		}
	}

	public void countOne2OneSupportTypeGiven()
	{
		List<aggregateResult> supportResults = [select Region__c, Type_of_One_to_one_support__c, count(ID) support from Event where WhoID in (select ID from Contact where ID in :clientsSupportedThisMonth) and StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth and Type_of_event__c = 'One to one support' group by Region__c, Type_of_One_to_one_support__c];
		for (aggregateResult ar : supportResults)
		{
			String typeOfSupportName = (String)ar.get('Type_of_One_to_one_support__c');
			if (typeOfSupportName == null) typeOfSupportName = 'Not specified';
			
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.one2onesupporttypes.put(typeOfSupportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.one2onesupporttypes.put(typeOfSupportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.one2onesupporttypes.put(typeOfSupportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.one2onesupporttypes.put(typeOfSupportName, (Integer)ar.get('support'));
			}
		}
	}

	public void countphoneSupportGiven()
	{
		List<aggregateResult> supportResults = [select Region__c, Reason_for_support__c, count(ID) support from Event where WhoID in (select ID from Contact where ID in :clientsSupportedThisMonth) and StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth and Type_of_event__c LIKE '%phone%' group by Region__c, Reason_for_support__c];
		for (aggregateResult ar : supportResults)
		{
			String supportName = (String)ar.get('Reason_for_support__c');
			if (supportName == null) supportName = 'Not specified';
			
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.phoneSupportCalls += (Integer)ar.get('support');
				Region1.phoneSupportReasons.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.phoneSupportCalls += (Integer)ar.get('support');
				Region2.phoneSupportReasons.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.phoneSupportCalls += (Integer)ar.get('support');
				Region3.phoneSupportReasons.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.phoneSupportCalls += (Integer)ar.get('support');
				Region4.phoneSupportReasons.put(supportName, (Integer)ar.get('support'));
			}
		}
	}

	public void countOne2OneSupportClients()
	{
		List<aggregateResult> results = [select Region__c, count(ID) region from Contact where id in :clientsOneToOneSupportThisMonth group by Region__c];
		for (aggregateResult ar : results)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.one2oneClients += (Integer)ar.get('region');
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.one2oneClients += (Integer)ar.get('region');
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.one2oneClients += (Integer)ar.get('region');
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.one2oneClients += (Integer)ar.get('region');
		}
	}

	public override void countReferralsOutTotals ()
	{
		List<aggregateResult> referralResults = [select Region__c, Gender__c, count(ID) gender
			from Contact where id in :clientsWithReferralsOutSupportedThisMonth group by Region__c, Gender__c];
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region1.maleReferralsOut = (Integer)ar.get('gender');
				else Region1.femaleReferralsOut = (Integer)ar.get('gender');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region2.maleReferralsOut = (Integer)ar.get('gender');
				else Region2.femaleReferralsOut = (Integer)ar.get('gender');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region3.maleReferralsOut = (Integer)ar.get('gender');
				else Region3.femaleReferralsOut = (Integer)ar.get('gender');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region4.maleReferralsOut = (Integer)ar.get('gender');
				else Region4.femaleReferralsOut = (Integer)ar.get('gender');
			}
		}
		Region1.totalReferralsOut = Region1.maleReferralsOut + Region1.femaleReferralsOut;
		Region2.totalReferralsOut = Region2.maleReferralsOut + Region2.femaleReferralsOut;
		Region3.totalReferralsOut = Region3.maleReferralsOut + Region3.femaleReferralsOut;
		Region4.totalReferralsOut = Region4.maleReferralsOut + Region4.femaleReferralsOut;
	}
	
	public void countReferralsOutAndAdvocacy ()
	{
		List <Event> referralsOut = [select WhoID, Region__c, 
			Social_and_or_Occupational_reintegration__c, CADS_HSE__c, SIMON_Community__c, Aftercare_MQI_MQI_Outreach__c, Traveller_Mediation__c,
			Traveller_Community_Development__c, Suicide_Awareness_Officer__c, Other_refuge__c, Detox_Programme__c, Community_GP__c, Medication_free_therapy__c,
			Traveller_Health_Unit__c, Complimentary_Therapies__c, Ana_Liffey_Drug_Project__c, Community_Detox__c, 
			CADS_HSE_Advocacy__c, Further_Education__c, Housing__c, Other_Clothing__c, Prison__c, Social_Welfare__c, SVDP__c, Methadone_Maintenance_Programme__c 
 			from Event where WhoID in :clientsSupportedThisMonth and StartDateTime >= :startOfMonth and StartDateTime < :endOfMonthPlus1];
		
		for (Event ev: referralsOut)
		{
			if (ev.Region__c == 'Longford')
			{
				incrementReferralsOutInRegion (region1, ev);
				incrementAdvocacyInRegion (region1, ev);
			}
			else if (ev.Region__c == 'Westmeath')
			{
				incrementReferralsOutInRegion (region2, ev);
				incrementAdvocacyInRegion (region2, ev);
			}
			else if (ev.Region__c == 'Laois')
			{
				incrementReferralsOutInRegion (region3, ev);
				incrementAdvocacyInRegion (region3, ev);
			}
			else if (ev.Region__c == 'Offaly')
			{
				incrementReferralsOutInRegion (region4, ev);
				incrementAdvocacyInRegion (region4, ev);
			}
		}
		
	}
	
	public void countFamilySupportGroups ()
	{
		List<aggregateResult> supportResults = [select Region__c, count(ID) sessions from Program_Session__c where Session_Date__c >= :startOfMonth and Session_Date__c <= :endOfMonth and Program_Service__r.Course_Type__c = 'Family support' group by Region__c];
		for (aggregateResult ar : supportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.FamilySupportGroupSessions += (Integer)ar.get('sessions');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.FamilySupportGroupSessions += (Integer)ar.get('sessions');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.FamilySupportGroupSessions += (Integer)ar.get('sessions');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.FamilySupportGroupSessions += (Integer)ar.get('sessions');
			}
		}
	}
	
	public void countNewFamilySupportGroups ()
	{
		List<aggregateResult> supportResults = [select Region__c, count(ID) groups from Program_Service__c where Start_Date__c >= :startOfMonth and Start_Date__c <= :endOfMonth and Course_Type__c = 'Family support' group by Region__c];
		for (aggregateResult ar : supportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.NewFamilySupportGroups += (Integer)ar.get('groups');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.NewFamilySupportGroups += (Integer)ar.get('groups');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.NewFamilySupportGroups += (Integer)ar.get('groups');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.NewFamilySupportGroups += (Integer)ar.get('groups');
			}
		}
	}
/*
	public void countClosedFamilySupportGroups ()
	{
		List<aggregateResult> supportResults = [select Region__c, count(ID) groups from Program_Service__c where End_Date__c >= :startOfMonth and End_Date__c <= :endOfMonth and Course_Type__c = 'Family support' group by Region__c];
		for (aggregateResult ar : supportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.ClosedFamilySupportGroups += (Integer)ar.get('groups');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.ClosedFamilySupportGroups += (Integer)ar.get('groups');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.ClosedFamilySupportGroups += (Integer)ar.get('groups');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.ClosedFamilySupportGroups += (Integer)ar.get('groups');
			}
		}
	}
*/
	public void countIndividualsInFamilySupportGroups ()
	{
		// do this without the aggregate so that clients can be counted
		List<Contact> results = [select Region__c, ID from Contact where id in (select Young_Person__c from Attendance__c where Attended__c = true and Date_of_Session__c >= :startOfMonth and Date_of_Session__c <= :endOfMonth and Program_Session__r.Program_Service__r.Course_Type__c = 'Family support')];
		for (Contact client : results)
		{
			caseLoadClients.add(client.ID);
			clientsSupportedThisMonth.add(client.ID);
			if (client.Region__c == 'Longford')
				Region1.FamilySupportGroupClients++;
			else if (client.Region__c == 'Westmeath')
				Region2.FamilySupportGroupClients++;
			else if (client.Region__c == 'Laois')
				Region3.FamilySupportGroupClients++;
			else if (client.Region__c == 'Offaly')
				Region4.FamilySupportGroupClients++;
		}
	}
/*	
	public void countIndividualsInNewFamilySupportGroups ()
	{
		List<aggregateResult> results = [select Region__c, count(ID) region from Contact where id in (select Young_Person__c from Attendance__c where Date_of_Session__c >= :startOfMonth and Date_of_Session__c <= :endOfMonth and Program_Session__r.Program_Service__r.Course_Type__c = 'Family support'
			and Program_Session__r.Program_Service__r.Start_Date__c >= :startOfMonth and Program_Session__r.Program_Service__r.Start_Date__c <= :endOfMonth) group by Region__c];
		for (aggregateResult ar : results)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.NewFamilySupportGroupClients += (Integer)ar.get('region');
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.NewFamilySupportGroupClients += (Integer)ar.get('region');
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.NewFamilySupportGroupClients += (Integer)ar.get('region');
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.NewFamilySupportGroupClients += (Integer)ar.get('region');
		}
	}
*/
	public static testMethod void attendeesTest ()
	{
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self');
		cl1.Family_Support_Client__c=true;
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od1.DurationInMinutes=60;
		insert od1;
		
		system.assert ([select Family_Support_Client__c from Event where id = :od1.id].Family_Support_Client__c);

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl2.Family_Support_Client__c=true;
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,2,2,2), None__c=true, Days_since_last_activity__c=70);
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl3.Family_Support_Client__c=true;
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,3,3,3), None__c=true, Days_since_last_activity__c=70);
		od3.DurationInMinutes=60;
		od3.Social_Welfare__c = true;
		insert od3;

		Contact cl4 = new Contact (LastName='Test4', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Self');
		cl4.Family_Support_Client__c=true;
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od4.DurationInMinutes=60;
		insert od4;

		Contact cl5 = new Contact (LastName='Test5', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Self');
		cl5.Family_Support_Client__c=true;
		insert cl5;
		Event od5 = new Event (WhoID = cl5.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od5.DurationInMinutes=60;
		insert od5;

		Contact cl6 = new Contact (LastName='Test6', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Self');
		cl6.Family_Support_Client__c=true;
		insert cl6;
		Event od6 = new Event (WhoID = cl6.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od6.DurationInMinutes=60;
		insert od6;
		
		Contact cl7 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Gardai');
		cl7.Family_Support_Client__c=true;
		insert cl7;
		Event od7 = new Event (WhoID = cl7.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,2,2,2), None__c=true, Days_since_last_activity__c=70);
		od7.DurationInMinutes=60;
		insert od7;

		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where Family_Support_Client__c = true]);
		FamilySupportSummaryData msd = new FamilySupportSummaryData (Date.newInstance(2012,1,31), clientsMap.keySet());

		system.assertEquals (3, msd.Region1.newAttendees);
		system.assertEquals (2, msd.Region1.newFemales);
		system.assertEquals (1, msd.Region1.newMales);

		system.assertEquals (2, msd.Region2.newAttendees);
		system.assertEquals (1, msd.Region2.newFemales);
		system.assertEquals (1, msd.Region2.newMales);

		system.assertEquals (1, msd.Region3.newAttendees);
		system.assertEquals (1, msd.Region3.newFemales);
		system.assertEquals (0, msd.Region3.newMales);

		system.assertEquals (1, msd.Region4.newAttendees);
		system.assertEquals (0, msd.Region4.newFemales);
		system.assertEquals (1, msd.Region4.newMales);
	}
	
	public static testMethod void referralsInTest ()
	{
		system.debug ('Start referralsInTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self');
		cl1.Family_Support_Client__c=true;
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl2.Family_Support_Client__c=true;
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70);
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl3.Family_Support_Client__c=true;
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70);
		od3.DurationInMinutes=60;
		od3.Social_Welfare__c = true;
		insert od3;

		Contact cl4 = new Contact (LastName='Test4', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Gardai');
		cl4.Family_Support_Client__c=true;
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70);
		od4.DurationInMinutes=60;
		od4.Social_Welfare__c = true;
		insert od4;

		Contact cl5 = new Contact (LastName='Test5', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Self');
		cl5.Family_Support_Client__c=true;
		insert cl5;
		Event od5 = new Event (WhoID = cl5.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od5.DurationInMinutes=60;
		insert od5;

		Contact cl6 = new Contact (LastName='Test6', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Self');
		cl6.Family_Support_Client__c=true;
		insert cl6;
		Event od6 = new Event (WhoID = cl6.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od6.DurationInMinutes=60;
		insert od6;

		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where Family_Support_Client__c = true]);
		FamilySupportSummaryData msd = new FamilySupportSummaryData (system.today().addDays(1), clientsMap.keySet());

		system.assertEquals (1, msd.Region1.maleReferralsIn);
		system.assertEquals (2, msd.Region1.femaleReferralsIn);
		system.assertEquals (3, msd.Region1.totalReferralsIn);
		system.assertEquals (2, msd.Region1.referralsIn.get('Gardai'));
		system.assertEquals (1, msd.Region2.totalReferralsIn);
		system.assertEquals (1, msd.Region3.maleReferralsIn);
		system.assertEquals (1, msd.Region4.femaleReferralsIn);
	
		system.debug ('End referralsInTest');
	}
	
	public static testMethod void referralsOutTest ()
	{
		system.debug ('Start referralsOutTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), None__c=true, Days_since_last_activity__c=70);
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od2.Simon_Community__c = true;
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od3.Simon_Community__c = true;
		od3.Social_Welfare__c = true;
		od3.DurationInMinutes=60;
		insert od3;

		Contact cl4 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4.Simon_Community__c = true;
		od4.Social_Welfare__c = true;
		od4.DurationInMinutes=60;
		insert od4;

		Event od4a = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4a.Simon_Community__c = true;
		od4a.Social_Welfare__c = true;
		od4a.DurationInMinutes=60;
		insert od4a;

		Contact cl5 = new Contact (LastName='Test5', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl5;
		Event od5 = new Event (WhoID = cl5.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od5.DurationInMinutes=60;
		od5.Simon_Community__c = true;
		insert od5;

		Contact cl6 = new Contact (LastName='Test6', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl6;
		Event od6 = new Event (WhoID = cl6.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od6.DurationInMinutes=60;
		od6.Simon_Community__c = true;
		insert od6;

		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where Family_Support_Client__c = true]);
		FamilySupportSummaryData msd = new FamilySupportSummaryData (Date.newInstance(2012,7,31), clientsMap.keySet());

		system.assertEquals (1, msd.Region1.maleReferralsOut);
		system.assertEquals (1, msd.Region1.femaleReferralsOut);
		system.assertEquals (2, msd.Region1.totalReferralsOut);
		system.assertEquals (1, msd.Region2.totalReferralsOut);
		system.assertEquals (1, msd.Region3.totalReferralsOut);
		system.assertEquals (1, msd.Region4.totalReferralsOut);
		
		system.debug ('End referralsInTest');
	}

	public static testMethod void oneToOneTest ()
	{
		system.debug ('Start referralsOutTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Type_of_event__c = 'One to one support');
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70, Type_of_event__c = 'One to one support');
		od2.Simon_Community__c = true;
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70, Type_of_event__c = 'Client support phone call');
		od3.Simon_Community__c = true;
		od3.Social_Welfare__c = true;
		od3.DurationInMinutes=60;
		insert od3;

		Contact cl4 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4.Type_of_event__c = 'Family support session';
		od4.Simon_Community__c = true;
		od4.Social_Welfare__c = true;
		od4.DurationInMinutes=60;
		insert od4;

		Event od4a = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4a.Simon_Community__c = true;
		od4a.Social_Welfare__c = true;
		od4a.DurationInMinutes=60;
		insert od4a;

		Contact cl5 = new Contact (LastName='Test5', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl5;
		Event od5 = new Event (WhoID = cl5.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od5.DurationInMinutes=60;
		od5.Simon_Community__c = true;
		insert od5;

		Contact cl6 = new Contact (LastName='Test6', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl6;
		Event od6 = new Event (WhoID = cl6.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od6.DurationInMinutes=60;
		od6.Simon_Community__c = true;
		insert od6;

		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where Family_Support_Client__c = true]);
		FamilySupportSummaryData msd = new FamilySupportSummaryData (Date.newInstance(2012,7,31), clientsMap.keySet());

		system.assertEquals (1, msd.Region1.maleReferralsOut);
		system.assertEquals (1, msd.Region1.femaleReferralsOut);
		system.assertEquals (2, msd.Region1.totalReferralsOut);
		system.assertEquals (1, msd.Region2.totalReferralsOut);
		system.assertEquals (1, msd.Region3.totalReferralsOut);
		system.assertEquals (1, msd.Region4.totalReferralsOut);
		
		system.debug ('End referralsInTest');
	}
	
	public static testMethod void oneToOneTestOffaly ()
	{
		system.debug ('Start referralsOutTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Type_of_event__c = 'One to one support');
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70, Type_of_event__c = 'One to one support');
		od2.Simon_Community__c = true;
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70, Type_of_event__c = 'Client support phone call');
		od3.Simon_Community__c = true;
		od3.Social_Welfare__c = true;
		od3.DurationInMinutes=60;
		insert od3;

		Contact cl4 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Gardai',Family_Support_Client__c=true);
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4.Type_of_event__c = 'Family support session';
		od4.Simon_Community__c = true;
		od4.Social_Welfare__c = true;
		od4.DurationInMinutes=60;
		insert od4;

		Event od4a = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4a.Simon_Community__c = true;
		od4a.Social_Welfare__c = true;
		od4a.DurationInMinutes=60;
		insert od4a;

		Contact cl5 = new Contact (LastName='Test5', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl5;
		Event od5 = new Event (WhoID = cl5.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od5.DurationInMinutes=60;
		od5.Simon_Community__c = true;
		insert od5;

		Contact cl6 = new Contact (LastName='Test6', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Offaly',Heroin__c=true, Source_of_referral__c='Self',Family_Support_Client__c=true);
		insert cl6;
		Event od6 = new Event (WhoID = cl6.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od6.DurationInMinutes=60;
		od6.Simon_Community__c = true;
		insert od6;

		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where Family_Support_Client__c = true]);
		FamilySupportSummaryData msd = new FamilySupportSummaryData (Date.newInstance(2012,7,31), clientsMap.keySet());
	}
}