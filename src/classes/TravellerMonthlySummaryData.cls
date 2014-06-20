// no further development after March 2013
public class TravellerMonthlySummaryData extends MonthSummaryData
{
	private Set<ID>clientsWithReferralsOutSupportedThisMonth=new Set<ID>();
	private Set<ID>newclientsThisMonth=new Set<ID>();
	private Date endOfMonthPlus1;
	
	public TravellerMonthlySummaryData (Date eom)
	{
		super(eom);
		endOfMonthPlus1 = endOfMonth.addDays(1);
		
		clientsWithReferralsOutSupportedThisMonth.clear();
		newclientsThisMonth.clear();
		
		for (Event oneEvent: [select WhoID, None__c, Days_since_last_activity__c from Event where StartDateTime >= :startOfMonth and StartDateTime < :endOfMonthPlus1 and Member_of_travelling_community__c=true])
		{
			clientsSupportedThisMonth.add(oneEvent.WhoID);
			System.debug ('Client supported ' + oneEvent.WhoID + ' ' + startOfMonth);
			if (!oneEvent.None__c) 
			{
				clientsWithReferralsOutSupportedThisMonth.add(oneEvent.WhoID);
				System.debug ('Client with referral out supported ' + oneEvent.WhoID + ' ' + startOfMonth);
			}
			if (oneEvent.Days_since_last_activity__c==null || oneEvent.Days_since_last_activity__c>60) newclientsThisMonth.add(oneEvent.WhoID);
		}
		
		countNewAttendees();
		countTotalAndAge();		
		countClientTypes();
		countSupportGiven();
		countPrimaryDrugs();
		countCarePlans();
		countOpenDoorServicesAndReferrals ();
		countReferralsIn ();
		countReferralsOutTotals ();
		countReferralsOutAndAdvocacy ();
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
			}
			else
			{
				if ((String)ar.get('Region__c') == 'Longford') 
					Region1.newFemales = (Integer)ar.get('gender');
				else if ((String)ar.get('Region__c') == 'Westmeath') 
					Region2.newFemales = (Integer)ar.get('gender');
			}
		}			
		Region1.newAttendees = Region1.newMales + Region1.newFemales;
		Region2.newAttendees = Region2.newMales + Region2.newFemales;
	}
	
	public override void countTotalAndAge ()
	{
		List<Contact> clients = [select ID, Gender__c, Age__c, Region__c
			from Contact where id in :clientsSupportedThisMonth];
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
		}
	}
	
	public override void countClientTypes()
	{
		List<aggregateResult> results = [select Region__c, Type_of_client__c, count(ID) typeClient from Contact where id in :clientsSupportedThisMonth group by Region__c, Type_of_client__c];
		for (aggregateResult ar : results)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.clientTypes.put ((String)ar.get('Type_of_client__c'), (Integer)ar.get('typeClient'));
		}
	}

	public override void countPrimaryDrugs()
	{
		List<aggregateResult> drugResults = [select Region__c, Primary_Drug_Use__c, count(ID) primaryDrug from Contact where id in :clientsSupportedThisMonth group by Region__c, Primary_Drug_Use__c];
		for (aggregateResult ar : drugResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.primaryDrugTypes.put ((String)ar.get('Primary_Drug_Use__c'), (Integer)ar.get('primaryDrug'));
		}
	}
	
	public override void countCarePlans()
	{
		List<Care_Plan_Objective__c> carePlans = [select ID, Date_objective_set__c, Review_date__c, Date_completed__c, Client__r.Region__c
			from Care_Plan_Objective__c where Client__c in :clientsSupportedThisMonth and Date_objective_set__c != null];
		for (Care_Plan_Objective__c oneCarePlan: carePlans)
		{
			if (oneCarePlan.Client__r.Region__c == 'Longford')
			{
				if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) Region1.CarePlansInPlace++;
				if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region1.CarePlansCreated++;
				if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region1.CarePlansReviewed++;
				if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region1.CarePlansCompleted++;
			}
			else if (oneCarePlan.Client__r.Region__c == 'Westmeath')
			{
				if (oneCarePlan.Date_objective_set__c <= endOfMonth && (oneCarePlan.Date_completed__c == null || oneCarePlan.Date_completed__c >= startOfMonth)) Region2.CarePlansInPlace++;
				if (oneCarePlan.Date_objective_set__c >= startOfMonth && oneCarePlan.Date_objective_set__c <= endOfMonth) Region2.CarePlansCreated++;
				if (oneCarePlan.Review_date__c != null && oneCarePlan.Review_date__c >= startOfMonth && oneCarePlan.Review_date__c <= endOfMonth) Region2.CarePlansReviewed++;
				if (oneCarePlan.Date_completed__c != null && oneCarePlan.Date_completed__c >= startOfMonth && oneCarePlan.Date_completed__c <= endOfMonth) Region2.CarePlansCompleted++;
			}
		}
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
		}
		Region1.totalReferralsIn = Region1.maleReferralsIn + Region1.femaleReferralsIn;
		Region2.totalReferralsIn = Region2.maleReferralsIn + Region2.femaleReferralsIn;
	}
	
	public void countSupportGiven()
	{
		List<aggregateResult> supportResults = [select Region__c, Type_of_Event__c, count(ID) support from Event where WhoID in (select ID from Contact where Member_of_travelling_community__c=true) and StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth group by Region__c, Type_of_Event__c];
		for (aggregateResult ar : supportResults)
		{
			String supportName = (String)ar.get('Type_of_Event__c');
			if (supportName == null) supportName = 'Not specified';
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.supports.put(supportName, (Integer)ar.get('support'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.supports.put(supportName, (Integer)ar.get('support'));
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
			
		}
		Region1.totalReferralsOut = Region1.maleReferralsOut + Region1.femaleReferralsOut;
		Region2.totalReferralsOut = Region2.maleReferralsOut + Region2.femaleReferralsOut;
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
		}
	}
	
	public static testMethod void attendeesTest ()
	{
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self');
		cl1.Member_of_travelling_community__c=true;
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl2.Member_of_travelling_community__c=true;
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,2,2,2), None__c=true, Days_since_last_activity__c=70);
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl3.Member_of_travelling_community__c=true;
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,3,3,3), None__c=true, Days_since_last_activity__c=70);
		od3.DurationInMinutes=60;
		od3.Social_Welfare__c = true;
		insert od3;

		Contact cl4 = new Contact (LastName='Test4', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Self');
		cl4.Member_of_travelling_community__c=true;
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od4.DurationInMinutes=60;
		insert od4;

		Contact cl5 = new Contact (LastName='Test5', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Self');
		cl5.Member_of_travelling_community__c=true;
		insert cl5;
		Event od5 = new Event (WhoID = cl5.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,1,4,1,1,1), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od5.DurationInMinutes=60;
		insert od5;

		TravellerMonthlySummaryData msd = new TravellerMonthlySummaryData (Date.newInstance(2012,1,31));

		system.assertEquals (3, msd.Region1.newAttendees);
		system.assertEquals (2, msd.Region1.newFemales);
		system.assertEquals (1, msd.Region1.newMales);

		system.assertEquals (2, msd.Region2.newAttendees);
		system.assertEquals (1, msd.Region2.newFemales);
		system.assertEquals (1, msd.Region2.newMales);
	}
	
	public static testMethod void referralsInTest ()
	{
		system.debug ('Start referralsInTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self');
		cl1.Member_of_travelling_community__c=true;
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl2.Member_of_travelling_community__c=true;
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70);
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai');
		cl3.Member_of_travelling_community__c=true;
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70);
		od3.DurationInMinutes=60;
		od3.Social_Welfare__c = true;
		insert od3;

		Contact cl4 = new Contact (LastName='Test4', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Gardai');
		cl4.Member_of_travelling_community__c=true;
		insert cl4;
		Event od4 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=system.now(), None__c=true, Days_since_last_activity__c=70);
		od4.DurationInMinutes=60;
		od4.Social_Welfare__c = true;
		insert od4;

		TravellerMonthlySummaryData msd = new TravellerMonthlySummaryData (system.today().addDays(1));

		system.assertEquals (1, msd.Region1.maleReferralsIn);
		system.assertEquals (2, msd.Region1.femaleReferralsIn);
		system.assertEquals (3, msd.Region1.totalReferralsIn);
		system.assertEquals (2, msd.Region1.referralsIn.get('Gardai'));
		system.assertEquals (1, msd.Region2.totalReferralsIn);
	
		system.debug ('End referralsInTest');
	}
	
	public static testMethod void referralsOutTest ()
	{
		system.debug ('Start referralsOutTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self',Member_of_travelling_community__c=true);
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), None__c=true, Days_since_last_activity__c=70);
		od1.DurationInMinutes=60;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai',Member_of_travelling_community__c=true);
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,1,1,1), Days_since_last_activity__c=70);
		od2.Simon_Community__c = true;
		od2.DurationInMinutes=60;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Gardai',Member_of_travelling_community__c=true);
		insert cl3;
		Event od3 = new Event (WhoID = cl3.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od3.Simon_Community__c = true;
		od3.Social_Welfare__c = true;
		od3.DurationInMinutes=60;
		od3.Housing__c = true;
		insert od3;

		Contact cl4 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Gardai',Member_of_travelling_community__c=true);
		insert cl4;
		Event od5 = new Event (WhoID = cl4.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od5.Simon_Community__c = true;
		od5.Social_Welfare__c = true;
		od5.DurationInMinutes=60;
		insert od5;

		Event od4 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,7,4,2,2,2), Days_since_last_activity__c=70);
		od4.Simon_Community__c = true;
		od4.Social_Welfare__c = true;
		od4.DurationInMinutes=60;
		od4.Housing__c = true;
		insert od4;

		Event od6 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=DateTime.newInstance(2012,8,4,2,2,2), Days_since_last_activity__c=7);
		od6.Simon_Community__c = true;
		od6.Social_Welfare__c = true;
		od6.DurationInMinutes=60;
		od6.Housing__c = true;
		insert od6;

		TravellerMonthlySummaryData msd = new TravellerMonthlySummaryData (Date.newInstance(2012,7,31));

		system.assertEquals (1, msd.Region1.maleReferralsOut);
		system.assertEquals (1, msd.Region1.femaleReferralsOut);
		system.assertEquals (2, msd.Region1.totalReferralsOut);
		system.assertEquals (1, msd.Region2.totalReferralsOut);
		
		system.assertEquals (2, msd.Region1.AdvocacyHousing);
		
		TravellerMonthlySummaryData msd1 = new TravellerMonthlySummaryData (Date.newInstance(2012,8,31));

		system.assertEquals (0, msd1.Region1.maleReferralsOut);
		system.assertEquals (1, msd1.Region1.femaleReferralsOut);
		system.assertEquals (1, msd1.Region1.totalReferralsOut);
		system.assertEquals (0, msd1.Region2.totalReferralsOut);
		
		system.assertEquals (1, msd1.Region1.AdvocacyHousing);

		system.debug ('End referralsInTest');
	}
	
	public static testMethod void carePlansTest ()
	{
		system.debug ('Start carePlansTest');
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Longford',Heroin__c=true, Source_of_referral__c='Self');
		cl1.Member_of_travelling_community__c=true;
		insert cl1;
		Event od1 = new Event (WhoID = cl1.id, OwnerID=UserInfo.getUserId(), StartDateTime=Date.newInstance(2012,7,15), None__c=true, Days_since_last_activity__c=70, Subject='Test');
		od1.DurationInMinutes=60;
		insert od1;
		
		Care_Plan_Objective__c cp1 = new Care_Plan_Objective__c (Name='Care plan 1', Client__c=cl1.id, Date_objective_set__c=Date.newInstance(2012,7,15), Review_date__c=Date.newInstance(2012,7,25), Date_completed__c=Date.newInstance(2012,8,15));
		insert cp1;
		Care_Plan_Objective__c cp1a = new Care_Plan_Objective__c (Name='Care plan 1a', Client__c=cl1.id, Date_objective_set__c=Date.newInstance(2012,7,15));
		insert cp1a;
		
		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Westmeath',Heroin__c=true, Source_of_referral__c='Gardai');
		cl2.Member_of_travelling_community__c=true;
		insert cl2;
		Event od2 = new Event (WhoID = cl2.id, OwnerID=UserInfo.getUserId(), StartDateTime=Date.newInstance(2012,7,15), None__c=true, Days_since_last_activity__c=70);
		od2.DurationInMinutes=60;
		insert od2;

		Care_Plan_Objective__c cp2 = new Care_Plan_Objective__c (Name='Care plan 2', Client__c=cl2.id, Date_objective_set__c=Date.newInstance(2012,7,15), Review_date__c=Date.newInstance(2012,7,25), Date_completed__c=Date.newInstance(2012,8,15));
		insert cp2;

		TravellerMonthlySummaryData msd = new TravellerMonthlySummaryData (Date.newInstance(2012,7,31));
		system.assertEquals (2, msd.Region1.CarePlansCreated);
		system.assertEquals (1, msd.Region2.CarePlansCreated);
		system.assertEquals (2, msd.Region1.CarePlansInPlace);
		system.assertEquals (1, msd.Region1.CarePlansReviewed);

		system.debug ('End carePlansTest');
	}
	
}