public with sharing class RehabSummaryData extends MonthSummaryData
{
	private Set<ID>clientsWithReferralsOutSupportedThisMonth=new Set<ID>();
	private Set<ID>newclientsThisMonth=new Set<ID>();
	private Set<ID>clientsOneToOneSupportThisMonth=new Set<ID>();
	Date endOfMonthPlus1;
	
	public RehabSummaryData (Date eom, Set<ID> aftercareClients)
	{
		super(eom);

		endOfMonthPlus1 = endOfMonth.addDays(1);
		system.debug ('Aftercare clients: ' + aftercareClients);
		for (Event oneEvent: [select WhoID, None__c, Days_since_last_activity__c, Type_of_event__c, StartDateTime from Event where StartDateTime >= :caseLoadStart and StartDateTime < :endOfMonthPlus1 and whoid in :aftercareClients])
		{
			system.debug ('Event: ' + oneEvent);
			caseLoadClients.add(oneEvent.WhoID);
			if (oneEvent.StartDateTime >= startOfMonth) 
			{
				clientsSupportedThisMonth.add(oneEvent.WhoID);
				if (!oneEvent.None__c) clientsWithReferralsOutSupportedThisMonth.add(oneEvent.WhoID);
				if (oneEvent.Days_since_last_activity__c==null || oneEvent.Days_since_last_activity__c>60) newclientsThisMonth.add(oneEvent.WhoID);
				if (oneEvent.Type_of_event__c == 'One to one support') clientsOneToOneSupportThisMonth.add (oneEvent.WhoID);
			}
		}

		countIndividualsInAftercareSupportGroups();
		countInterventionsGiven();
		countTotalAndAge();		
		countClientTypes();
		countPrimaryDrugs();
		countReferralsIn();
		countReferralsOutTotals();
		countReferralsOutAndAdvocacy();
		countLegalStatuses();
		countCarePlans();
		countAftercareSupportGroups();
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

	public void countInterventionsGiven()
	{
		List<aggregateResult> supportResults = [select Region__c, Type_of_event__c, count(ID) support from Event where WhoID in (select ID from Contact where ID in :clientsSupportedThisMonth) and StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth and (Type_of_event__c LIKE '%intervention%' or Type_of_event__c = 'One to one support') group by Region__c, Type_of_event__c];
		system.debug ('Intervention reasons: ' + supportResults);
		for (aggregateResult ar : supportResults)
		{
			String supportName = (String)ar.get('Type_of_event__c');
			if (supportName == null) supportName = 'Not specified';
			
			if ((String)ar.get('Region__c') == 'Longford')
			{
			system.debug ('Intervention reasons count Longford: ' + (Integer)ar.get('support'));
				Region1.interventionReasons.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
			system.debug ('Intervention reasons count Westmeath: ' + (Integer)ar.get('support'));
				Region2.interventionReasons.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
			system.debug ('Intervention reasons count Laois: ' + (Integer)ar.get('support') + ' support name: ' + supportName);
				Region3.interventionReasons.put(supportName, (Integer)ar.get('support'));
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
			system.debug ('Intervention reasons count Offaly: ' + (Integer)ar.get('support'));
				Region4.interventionReasons.put(supportName, (Integer)ar.get('support'));
			}
		}
	}

	public void countAftercareSupportGroups ()
	{
		List<aggregateResult> supportResults = [select Region__c, count(ID) sessions from Program_Session__c where Session_Date__c >= :startOfMonth and Session_Date__c <= :endOfMonth and Program_Service__r.Course_Type__c = 'Aftercare support' group by Region__c];
		for (aggregateResult ar : supportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.AftercareSupportGroupSessions += (Integer)ar.get('sessions');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.AftercareSupportGroupSessions += (Integer)ar.get('sessions');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.AftercareSupportGroupSessions += (Integer)ar.get('sessions');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.AftercareSupportGroupSessions += (Integer)ar.get('sessions');
			}
		}
	}

	public void countIndividualsInAftercareSupportGroups ()
	{
		// do this without the aggregate so that clients can be counted
		List<Contact> results = [select Region__c, ID from Contact where id in (select Young_Person__c from Attendance__c where Attended__c = true and Date_of_Session__c >= :startOfMonth and Date_of_Session__c <= :endOfMonth and Program_Session__r.Program_Service__r.Course_Type__c = 'Aftercare support')];
		for (Contact client : results)
		{
			caseLoadClients.add(client.ID);
			clientsSupportedThisMonth.add(client.ID);
			if (client.Region__c == 'Longford')
				Region1.AftercareSupportGroupClients++;
			else if (client.Region__c == 'Westmeath')
				Region2.AftercareSupportGroupClients++;
			else if (client.Region__c == 'Laois')
				Region3.AftercareSupportGroupClients++;
			else if (client.Region__c == 'Offaly')
				Region4.AftercareSupportGroupClients++;
		}
	}

	// EK 25 August 2014 - Mark wants count of supported individuals with careplans in place 
	public override void countCarePlans()
	{
		set <ID> individualsWithCarePlansLongford = new set <ID>();
		set <ID> individualsWithCarePlansWestmeath = new set <ID>();
		set <ID> individualsWithCarePlansLaois = new set <ID>();
		set <ID> individualsWithCarePlansOffaly = new set <ID>();
		List<Care_Plan_Objective__c> carePlans = [select ID, Date_objective_set__c, Review_date__c, Date_completed__c, Client__r.Region__c, Client__c
			from Care_Plan_Objective__c where Client__c in :clientsSupportedThisMonth and Date_objective_set__c != null];
		for (Care_Plan_Objective__c oneCarePlan: carePlans)
		{
			if (oneCarePlan.Client__r.Region__c == 'Longford')
			{
				if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) 
				{
					// Region1.CarePlansInPlace++;
					individualsWithCarePlansLongford.add (oneCarePlan.Client__c);
				}
				if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region1.CarePlansCreated++;
				if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region1.CarePlansReviewed++;
				if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region1.CarePlansCompleted++;
			}
			else if (oneCarePlan.Client__r.Region__c == 'Westmeath')
			{
				if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) 
				{
					// Region2.CarePlansInPlace++;
					individualsWithCarePlansWestmeath.add (oneCarePlan.Client__c);
				}
				if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region2.CarePlansCreated++;
				if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region2.CarePlansReviewed++;
				if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region2.CarePlansCompleted++;
			}
			else if (oneCarePlan.Client__r.Region__c == 'Laois')
			{
				if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) 
				{
					// Region3.CarePlansInPlace++;
					individualsWithCarePlansLaois.add (oneCarePlan.Client__c);
				}
				if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region3.CarePlansCreated++;
				if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region3.CarePlansReviewed++;
				if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region3.CarePlansCompleted++;
			}
			else if (oneCarePlan.Client__r.Region__c == 'Offaly')
			{
				if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) 
				{
					// Region4.CarePlansInPlace++;
					individualsWithCarePlansOffaly.add (oneCarePlan.Client__c);
				}
				if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region4.CarePlansCreated++;
				if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region4.CarePlansReviewed++;
				if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region4.CarePlansCompleted++;
			}
		}
		Region1.CarePlansInPlace = individualsWithCarePlansLongford.size();
		Region2.CarePlansInPlace = individualsWithCarePlansWestmeath.size();
		Region3.CarePlansInPlace = individualsWithCarePlansLaois.size();
		Region4.CarePlansInPlace = individualsWithCarePlansOffaly.size();
	}

	public override void countNewAttendees ()
	{
	}
	
	public override void countPrimaryDrugs()
	{
		List<aggregateResult> drugResults = [select Region__c, Primary_Drug_Use__c, count(ID) primaryDrug from Contact where id in :caseLoadClients group by Region__c, Primary_Drug_Use__c];
		for (aggregateResult ar : drugResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
		}
	}
	
	public void countLegalStatuses()
	{
		List<aggregateResult> drugResults = [select Region__c, Legal_Status__c, count(ID) legal from Contact where id in :caseLoadClients group by Region__c, Legal_Status__c];
		for (aggregateResult ar : drugResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.legalStatuses.put ((String)ar.get('Legal_Status__c'), (Integer)ar.get('legal'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.legalStatuses.put ((String)ar.get('Legal_Status__c'), (Integer)ar.get('legal'));
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.legalStatuses.put ((String)ar.get('Legal_Status__c'), (Integer)ar.get('legal'));
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.legalStatuses.put ((String)ar.get('Legal_Status__c'), (Integer)ar.get('legal'));
		}
	}
	
	public override void countReferralsIn () 
	{
		Date endMonthplus1 = endOfMonth.addDays(1);
		List<aggregateResult> referralResults = [select Region__c, Source_of_referral__c, count(ID) referral
			from Contact where id in :clientsSupportedThisMonth and CreatedDate >= :startOfMonth and CreatedDate < :endMonthplus1 group by Region__c, Source_of_referral__c];
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
	
	public static void createTestObjects ()
	{
		createCountyTestObjects ('Laois');
		createCountyTestObjects ('Longford');
		createCountyTestObjects ('Offaly');
//		createCountyTestObjects ('Westmeath'); // too many SOQL statements when I include this one
	}
	
	public static void createCountyTestObjects (String county)
	{
		List <Contact> newContacts = new List <Contact>();
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c=county,Heroin__c=true, Source_of_referral__c='Self', Aftercare_Client__c=true);
		newContacts.add (cl1);
		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c=county,Heroin__c=true, Source_of_referral__c='Gardai', Aftercare_Client__c=true);
		newContacts.add (cl2);
		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c=county,Heroin__c=true, Source_of_referral__c='Gardai', Aftercare_Client__c=true);
		newContacts.add (cl3);
		
		insert newContacts;

		List <Event> newEvents = new List <Event>();
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=Date.newInstance(system.today().year(),system.today().month(),28), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od1.DurationInMinutes=60;
		newEvents.add(od1);

		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=Date.newInstance(system.today().year(),system.today().month(),28), Days_since_last_activity__c=70, Subject='Test');
		od2.DurationInMinutes=60;
		od2.Community_GP__c = true;
		newEvents.add(od2);

		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=Date.newInstance(system.today().year(),system.today().month(),28), Days_since_last_activity__c=70, Subject='Test');
		od3.DurationInMinutes=60;
		od3.Community_GP__c = true;
		newEvents.add(od3);
		
		insert newEvents;
	}
	
	public static testMethod void referralsInTest ()
	{
		RehabSummaryData.createTestObjects();
		test.startTest();
		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where aftercare_client__c = true]);
		
		RehabSummaryData msd = new RehabSummaryData (Date.newInstance(system.today().year(),system.today().month(),28), clientsMap.keySet());
		test.stopTest();
		system.assertEquals (1, msd.Region3.maleReferralsIn);
		system.assertEquals (2, msd.Region3.femaleReferralsIn);
		system.assertEquals (3, msd.Region3.totalReferralsIn);
		system.assertEquals (2, msd.Region3.referralsIn.get('Gardai'));
	}
	
	public static testMethod void referralsOutTest ()
	{
		RehabSummaryData.createTestObjects();
		Map <ID,Contact>clientsMap = new Map<id,contact>([select id from Contact where aftercare_client__c = true]);
		
		RehabSummaryData msd = new RehabSummaryData (Date.newInstance(system.today().year(),system.today().month(),28), clientsMap.keySet());

		
		system.assertEquals (1, msd.Region3.maleReferralsOut);
		system.assertEquals (1, msd.Region3.femaleReferralsOut);
		system.assertEquals (2, msd.Region3.totalReferralsOut);
		
		system.assertEquals (2, msd.Region1.RefOutCommunityGP);
	}	
}