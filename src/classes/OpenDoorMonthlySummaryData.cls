public class OpenDoorMonthlySummaryData extends MonthSummaryData 
{
	public OpenDoorMonthlySummaryData (Date eom)
	{
		super(eom);

		for (Open_Door_attendance__c oneEvent: [select Client__c, Date_of_attendance__c from Open_Door_attendance__c where Date_of_attendance__c >= :caseLoadStart and Date_of_attendance__c <= :endOfMonth])
		{
			caseLoadClients.add(oneEvent.Client__c);
			if (oneEvent.Date_of_attendance__c >= startOfMonth) 
				clientsSupportedThisMonth.add(oneEvent.Client__c);
		}

		countNewAttendees();
		countTotalAndAge();		
		countClientTypes();
		countClientsFromEstates();
		countPrimaryDrugs();
		countCarePlans();
		countOpenDoorServicesAndReferrals ();
		countReferralsIn ();
		countReferralsOutTotals ();
	}
	
	public override void countNewAttendees ()
	{
		List<Open_Door_attendance__c> attendances = [select ID, Client_gender__c, Client_age__c from Open_Door_attendance__c where Date_of_attendance__c >= :startOfMonth and Date_of_attendance__c <= :endOfMonth and (Days_since_last_activity__c=null or Days_since_last_activity__c>60)];
		for (Open_Door_attendance__c od: attendances)
		{
			if (od.Client_gender__c == 'Male') Region1.newMales++;
			else Region1.newFemales++;
		}
		Region1.newAttendees = attendances.size();
	}
	
	public override void countPrimaryDrugs()
	{
		List<aggregateResult> drugResults = [select Primary_Drug_Use__c, count(ID) primaryDrug from Contact where id in :caseLoadClients group by Primary_Drug_Use__c];
		for (aggregateResult ar : drugResults)
		{
			Region1.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
		}
	}
	
	// EK 25 August 2014 - Mark wants count of supported individuals with careplans in place 
	public override void countCarePlans()
	{
		set <ID> individualsWithCarePlans = new set <ID>();
		List<Care_Plan_Objective__c> carePlans = [select ID, Date_objective_set__c, Review_date__c, Date_completed__c, Client__c
			from Care_Plan_Objective__c where Client__c in :clientsSupportedThisMonth and Date_objective_set__c != null];
		for (Care_Plan_Objective__c oneCarePlan: carePlans)
		{
			if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) 
			{
				// Region1.CarePlansInPlace++;
				individualsWithCarePlans.add (oneCarePlan.Client__c);
			}
			if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region1.CarePlansCreated++;
			if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region1.CarePlansReviewed++;
			if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region1.CarePlansCompleted++;
		}
		Region1.CarePlansInPlace = individualsWithCarePlans.size();
	}
	
	public override void countReferralsIn ()
	{
		Date endMonthplus1 = endOfMonth.addDays(1);
		List<aggregateResult> referralResults = [select Source_of_referral__c, count(ID) referral
			from Contact where id in :clientsSupportedThisMonth and CreatedDate >= :startOfMonth and CreatedDate < :endMonthplus1 group by Source_of_referral__c];
		system.debug ('Number of clients supported: ' + clientsSupportedThisMonth.size());
		system.debug ('start of month ' + startOfMonth + ' end of month ' + endMonthplus1);
		system.debug ('Number of referrals in: ' + referralResults.size());
		for (aggregateResult ar : referralResults)
		{
			Region1.referralsIn.put ((String)ar.get('Source_of_referral__c'), (Integer)ar.get('referral'));
		}

		referralResults = [select Gender__c, count(ID) gender
			from Contact where id in :clientsSupportedThisMonth and CreatedDate >= :startOfMonth and CreatedDate < :endMonthplus1 group by Gender__c];
		system.debug ('Number of referrals with gender: ' + referralResults.size());
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Gender__c') == 'Male') Region1.maleReferralsIn = (Integer)ar.get('gender');
			else Region1.femaleReferralsIn = (Integer)ar.get('gender');
		}
		Region1.totalReferralsIn = Region1.maleReferralsIn + Region1.femaleReferralsIn;
	}
	
	public void countClientsFromEstates()
	{
		List<aggregateResult> estateResults = [select Estate__c, count(ID) estateClient from Contact where id in :caseLoadClients group by Estate__c];
		for (aggregateResult ar : estateResults)
		{
			String estateName = (String)ar.get('Estate__c');
			if (estateName == null) estates.put ('Not specified', (Integer)ar.get('estateClient'));
			else estates.put(estateName, (Integer)ar.get('estateClient'));
		}
	}
	
	public override void countTotalAndAge ()
	{
		List<Contact> clients = [select ID, Gender__c, Age__c, Amphetamines__c, Heroin__c, Cocaine__c, Benzodiazepines__c, Legal_highs__c, Prescribed_Methadone__c,
			Street_Methadone__c, Ecstasy__c, Cannabis__c, Crack_cocaine__c, Alcohol__c, Crystal_Meth__c, OTC__c, Other_Please_Specify__c
			from Contact where id in (select Client__c from Open_Door_attendance__c where Date_of_attendance__c >= :caseLoadStart and Date_of_attendance__c <= :endOfMonth)];
		for (Contact oneClient: clients)
		{
			if (oneClient.Gender__c == 'Male') Region1.totalMales++;
			else Region1.totalFemales++;
			
			if (oneClient.Age__c == null) Region1.ageNone++;
			else if (oneClient.Age__c <= 17) Region1.age1++;
			else if (oneClient.Age__c <= 19) Region1.age2++;
			else if (oneClient.Age__c <= 24) Region1.age3++;
			else if (oneClient.Age__c <= 29) Region1.age4++;
			else if (oneClient.Age__c <= 34) Region1.age5++;
			else if (oneClient.Age__c <= 39) Region1.age6++;
			else if (oneClient.Age__c <= 44) Region1.age7++;
			else if (oneClient.Age__c <= 49) Region1.age8++;
			else Region1.age9++;
			
			if (oneClient.Amphetamines__c) Region1.Amphetamines++;
			if (oneClient.Heroin__c) Region1.Heroin++;
			if (oneClient.Cocaine__c) Region1.Cocaine++;
			if (oneClient.Benzodiazepines__c) Region1.Benzodiazepines++;
			if (oneClient.Legal_highs__c) Region1.Legalhighs++;
			if (oneClient.Prescribed_Methadone__c) Region1.PrescribedMethadone++;
			if (oneClient.Street_Methadone__c) Region1.StreetMethadone++;
			if (oneClient.Ecstasy__c) Region1.Ecstasy++;
			if (oneClient.Cannabis__c) Region1.Cannabis++;
			if (oneClient.Crack_cocaine__c) Region1.Crackcocaine++;
			if (oneClient.Alcohol__c) Region1.Alcohol++;
			if (oneClient.Crystal_Meth__c) Region1.CrystalMeth++;
			if (oneClient.OTC__c) Region1.OTC++;
			if (oneClient.Other_Please_Specify__c != null && oneClient.Other_Please_Specify__c.Length() > 0) Region1.Other++;
			
		}
		Region1.totalClients = clients.size();
	}
	
	public override void countClientTypes()
	{
		List<aggregateResult> results = [select Type_of_client__c, count(ID) typeClient from Contact where id in :caseLoadClients group by Type_of_client__c];
		for (aggregateResult ar : results)
		{
			Region1.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
		}
	}

	public override void countOpenDoorServicesAndReferrals ()
	{
		List<Open_Door_attendance__c> attendances = [select ID, Advice_and_Support_given__c, One_to_one_brief_intervention__c, Relapse_prevention__c,
			Laundry__c, Showers__c, Nutrition__c, Phone_call_out__c, Computer__c, Literacy__c, Placement_from_AIT__c, Placement_from_NLN_Shannon_Banks__c,
			Woodwork__c, Personal_Care__c, Stabilisation_group__c, 
			Arts_and_Crafts_Training__c, Cookery_class__c, Horticultural_Class__c,
			Community_Detox_Programme__c, Detox_Residential_Setting__c, Community_GP__c, CADS_MMP_C__c, Stepping_Out_Project__c, Complimentary_Therapies__c,
			VEC__c, Social_Welfare__c, TFE_Project__c, Housing_Officer__c, Ana_Liffey_Drug_Project__c, St_Marthas_Longford__c, Other_MQI_Service__c, Other_SIMON_Community__c
 			from Open_Door_attendance__c where Date_of_attendance__c >= :startOfMonth and Date_of_attendance__c <= :endOfMonth];
		for (Open_Door_attendance__c od: attendances)
		{
			Region1.totalVisits++;
			if (od.Advice_and_Support_given__c) Region1.AdviceAndSupport++;
			if (od.One_to_one_brief_intervention__c) Region1.One2One++;
			if (od.Relapse_prevention__c) Region1.RelapsePrevention++;
			
			if (od.Laundry__c) Region1.Laundry++;
			if (od.Showers__c) Region1.Showers++;
			if (od.Nutrition__c) Region1.Nutrition++;
			if (od.Phone_call_out__c) Region1.PhoneCallsOut++;
			if (od.Computer__c) Region1.Computer++;
			if (od.Literacy__c) Region1.LiteracySupport++;
			if (od.Placement_from_NLN_Shannon_Banks__c) Region1.PlacementfromNLN++;
			if (od.Placement_from_AIT__c) Region1.PlacementfromAIT++;
			if (od.Arts_and_Crafts_Training__c) Region1.ArtsandCraftsTraining++;
			if (od.Cookery_class__c) Region1.CookeryClasses++;
			if (od.Horticultural_Class__c) Region1.HorticulturalClasses++;
			if (od.Woodwork__c) Region1.Woodwork++;
			if (od.Personal_Care__c) Region1.Personal_Care++;
			if (od.Stabilisation_group__c) Region1.Stabilisation_group++;
			
			if (od.Community_Detox_Programme__c) Region1.CommunityDetoxProgramme++;
			if (od.Detox_Residential_Setting__c) Region1.DetoxResidentialSetting++;
			if (od.Community_GP__c) Region1.CommunityGP++;
			if (od.CADS_MMP_C__c) Region1.CADS++;
			if (od.Stepping_Out_Project__c) Region1.SteppingOutProject++;
			if (od.Complimentary_Therapies__c) Region1.ComplimentaryTherapies++;
			if (od.VEC__c) Region1.VEC++;
			if (od.Social_Welfare__c) Region1.SocialWelfare++;
			if (od.TFE_Project__c) Region1.TFEProject++;
			if (od.Housing_Officer__c) Region1.HousingOfficer++;
			if (od.Ana_Liffey_Drug_Project__c) Region1.AnaLiffeyDrugProject++;
			if (od.St_Marthas_Longford__c) Region1.StMarthasLongford++;
			if (od.Other_MQI_Service__c) Region1.OtherMQIService++;
			if (od.Other_SIMON_Community__c) Region1.OtherSIMONCommunity++;
		}

	}
	
	public override void countReferralsOutTotals ()
	{
		Region1.maleReferralsOut = 0;
		Region1.femaleReferralsOut = 0;
		List<aggregateResult> referralResults = [select Gender__c, count(ID) gender
			from Contact where id in (select Client__c from Open_Door_attendance__c where Date_of_attendance__c >= :startOfMonth and Date_of_attendance__c <= :endOfMonth and (not None__c=true)) group by Gender__c];
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Gender__c') == 'Male') Region1.maleReferralsOut = (Integer)ar.get('gender');
			else Region1.femaleReferralsOut = (Integer)ar.get('gender');
		}
		Region1.totalReferralsOut = Region1.maleReferralsOut + Region1.femaleReferralsOut;
		
	}
	
	public static testMethod void referralsInTest ()
	{
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Self');
		insert cl1;
		Open_Door_attendance__c od1 = new Open_Door_attendance__c (Client__c = cl1.id, Date_of_attendance__c=Date.newInstance(system.today().year(),system.today().month(),4), None__c=true, Days_since_last_activity__c=70);
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Gardai');
		insert cl2;
		Open_Door_attendance__c od2 = new Open_Door_attendance__c (Client__c = cl2.id, Date_of_attendance__c=Date.newInstance(system.today().year(),system.today().month(),4), None__c=true, Days_since_last_activity__c=70);
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Gardai');
		insert cl3;
		Open_Door_attendance__c od3 = new Open_Door_attendance__c (Client__c = cl3.id, Date_of_attendance__c=Date.newInstance(system.today().year(),system.today().month(),4), None__c=true, Days_since_last_activity__c=70);
		od3.Social_Welfare__c = true;
		insert od3;

		OpenDoorMonthlySummaryData msd = new OpenDoorMonthlySummaryData (Date.newInstance(system.today().year(),system.today().month(),28));

		msd.countReferralsIn();
		
		system.assertEquals (1, msd.Region1.maleReferralsIn);
		system.assertEquals (2, msd.Region1.femaleReferralsIn);
		system.assertEquals (3, msd.Region1.totalReferralsIn);
		system.assertEquals (2, msd.Region1.referralsIn.get('Gardai'));
		
		system.assertEquals (1, msd.Region1.SocialWelfare);
	}
	
	public static testMethod void referralsOutTest ()
	{
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Self');
		insert cl1;
		Open_Door_attendance__c od1 = new Open_Door_attendance__c (Client__c = cl1.id, Date_of_attendance__c=Date.newInstance(2012,7,4), None__c=true, Days_since_last_activity__c=70);
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Gardai');
		insert cl2;
		Open_Door_attendance__c od2 = new Open_Door_attendance__c (Client__c = cl2.id, Date_of_attendance__c=Date.newInstance(2012,7,4), Days_since_last_activity__c=70);
		od2.Social_Welfare__c = true;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Laois',Heroin__c=true, Source_of_referral__c='Gardai');
		insert cl3;
		Open_Door_attendance__c od3 = new Open_Door_attendance__c (Client__c = cl3.id, Date_of_attendance__c=Date.newInstance(2012,7,4), Days_since_last_activity__c=70);
		od3.Social_Welfare__c = true;
		insert od3;

		Open_Door_attendance__c od4 = new Open_Door_attendance__c (Client__c = cl3.id, Date_of_attendance__c=Date.newInstance(2012,7,4), Days_since_last_activity__c=70);
		od4.Social_Welfare__c = true;
		insert od4;

		OpenDoorMonthlySummaryData msd = new OpenDoorMonthlySummaryData (Date.newInstance(2012,7,31));

		msd.countReferralsOutTotals();
		
		system.assertEquals (1, msd.Region1.maleReferralsOut);
		system.assertEquals (1, msd.Region1.femaleReferralsOut);
		system.assertEquals (2, msd.Region1.totalReferralsOut);
		
		system.assertEquals (3, msd.Region1.SocialWelfare);
		
		system.assertEquals (4, msd.Region1.totalVisits);
	}	
}