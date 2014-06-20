public with sharing class NXSummaryData extends MonthSummaryData
{
	private Set<ID>NXWithReferralsOutSupportedThisMonth=new Set<ID>();
	Map <ID, Harm_Reduction_NX__c> harmReductionNXMap;
	Set <ID> clientsAvailOfNX = new Set<ID>();
	Set <ID> clientsNotAvailOfNX = new Set<ID>();
	public NXSummaryData (Date eom)
	{
		super(eom);

		harmReductionNXMap = new Map <ID, Harm_Reduction_NX__c> ([select Client__c, Needle_exchange_service_availed_of__c,
			Community_Detox_Programme__c, Detox_Residential_Setting__c, Community_GP__c, Other_MQI_Service__c, Other_referral_out__c, CADS__c, Medication_Free_Therapy__c, Complimentary_Therapies__c, Social_and_or_re_integration__c,
			Type_of_Intervention__c, Date_of_intervention__c
				from Harm_Reduction_NX__c where Date_of_intervention__c >= :caseLoadStart and Date_of_intervention__c <= :endOfMonth]);
				
		for (Harm_Reduction_NX__c oneEvent: harmReductionNXMap.values())
		{
			caseLoadClients.add(oneEvent.Client__c);
			if (oneEvent.Date_of_intervention__c >= startOfMonth) 
			{
				clientsSupportedThisMonth.add(oneEvent.Client__c);
				if (oneEvent.Needle_exchange_service_availed_of__c) clientsAvailOfNX.add (oneEvent.Client__c);
				if (oneEvent.Community_Detox_Programme__c || oneEvent.Detox_Residential_Setting__c || oneEvent.Community_GP__c || oneEvent.Other_MQI_Service__c || oneEvent.Other_referral_out__c || oneEvent.CADS__c || oneEvent.Medication_Free_Therapy__c || oneEvent.Complimentary_Therapies__c || oneEvent.Social_and_or_re_integration__c)
					NXWithReferralsOutSupportedThisMonth.add(oneEvent.ID);
			}
		}

		clientsNotAvailOfNX = clientsSupportedThisMonth.clone();
		clientsNotAvailOfNX.removeAll (clientsAvailOfNX);
		
		countTotalAndAge();		
		countClientTypes();
		countPrimaryDrugs();
		countInterventionTypes();
		countOutcomesSelfReport();
		countReferralsIn ();
		countReferralsOutTotals ();
		countClientsAvailedOfNX();
		countClientsNotAvailedOfNX();
		countNXMaterials ();
		countphoneSupportGiven();
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
	
	public void countInterventionTypes()
	{
		List<aggregateResult> interventionResults = [select Client__r.Region__c, Type_of_Intervention__c, count(ID) interventionType 
			from Harm_Reduction_NX__c where Date_of_intervention__c >= :startOfMonth and Date_of_intervention__c <= :endOfMonth
			group by Client__r.Region__c, Type_of_Intervention__c];
		for (aggregateResult ar : interventionResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.interventionTypes.put ((String)ar.get('Type_of_Intervention__c'), (Integer)ar.get('interventionType'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.interventionTypes.put ((String)ar.get('Type_of_Intervention__c'), (Integer)ar.get('interventionType'));
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.interventionTypes.put ((String)ar.get('Type_of_Intervention__c'), (Integer)ar.get('interventionType'));
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.interventionTypes.put ((String)ar.get('Type_of_Intervention__c'), (Integer)ar.get('interventionType'));
		}
	}
	
	public void countOutcomesSelfReport()
	{
		List<aggregateResult> OutcomesSelfReportResults = [select Client__r.Region__c, Outcomes_self_report__c, count(ID) outcome 
			from Harm_Reduction_NX__c where Date_of_intervention__c >= :startOfMonth and Date_of_intervention__c <= :endOfMonth
			group by Client__r.Region__c, Outcomes_self_report__c];
		for (aggregateResult ar : OutcomesSelfReportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
				Region1.outcomesSelfReports.put ((String)ar.get('Outcomes_self_report__c'), (Integer)ar.get('outcome'));
			else if ((String)ar.get('Region__c') == 'Westmeath')
				Region2.outcomesSelfReports.put ((String)ar.get('Outcomes_self_report__c'), (Integer)ar.get('outcome'));
			else if ((String)ar.get('Region__c') == 'Laois')
				Region3.outcomesSelfReports.put ((String)ar.get('Outcomes_self_report__c'), (Integer)ar.get('outcome'));
			else if ((String)ar.get('Region__c') == 'Offaly')
				Region4.outcomesSelfReports.put ((String)ar.get('Outcomes_self_report__c'), (Integer)ar.get('outcome'));
		}
	}
	
	public override void countReferralsIn () // also counts new clients - TODO
	{
		Date endMonthplus1 = endOfMonth.addDays(1);
		List<aggregateResult> referralResults = [select Region__c, Source_of_referral__c, count(ID) referral
			from Contact where id in :clientsSupportedThisMonth and CreatedDate >= :startOfMonth and CreatedDate < :endMonthplus1 group by Region__c, Source_of_referral__c];
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.referralsIn.put ((String)ar.get('Source_of_referral__c'), (Integer)ar.get('referral'));
				Region1.NXNewClients += (Integer)ar.get('referral');
			}
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
		List<aggregateResult> referralResults = [select Client__r.Region__c, Client__r.Gender__c, count(ID) gender, 
			count (Community_Detox_Programme_Count__c) communityDetox, count (Detox_Residential_Setting_count__c) residentialDetox, count (Community_GP_Count__c) gp, count (CADS_Count__c) CADS, 
			count (Medication_Free_Therapy_Count__c) meds, count (Complimentary_Therapies_Count__c) comp, count (Social_and_or_re_integration_Count__c) social,
			count (Other_MQI_Service_Count__c) otherMQI, count (Other_Referral_Count__c) otherOut 
			from Harm_Reduction_NX__c where id in :NXWithReferralsOutSupportedThisMonth group by Client__r.Region__c, Client__r.Gender__c];
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				if ((String)ar.get('Gender__c') == 'Male') 
					Region1.maleReferralsOut = (Integer)ar.get('gender');
				else 
					Region1.femaleReferralsOut = (Integer)ar.get('gender');
				Region1.accumulateNXReferralOutStats (ar);
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region2.maleReferralsOut = (Integer)ar.get('gender');
				else Region2.femaleReferralsOut = (Integer)ar.get('gender');
				Region2.accumulateNXReferralOutStats (ar);
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region3.maleReferralsOut = (Integer)ar.get('gender');
				else Region3.femaleReferralsOut = (Integer)ar.get('gender');
				Region3.accumulateNXReferralOutStats (ar);
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				if ((String)ar.get('Gender__c') == 'Male') Region4.maleReferralsOut = (Integer)ar.get('gender');
				else Region4.femaleReferralsOut = (Integer)ar.get('gender');
				Region4.accumulateNXReferralOutStats (ar);
			}
		}
		Region1.totalReferralsOut = Region1.maleReferralsOut + Region1.femaleReferralsOut;
		Region2.totalReferralsOut = Region2.maleReferralsOut + Region2.femaleReferralsOut;
		Region3.totalReferralsOut = Region3.maleReferralsOut + Region3.femaleReferralsOut;
		Region4.totalReferralsOut = Region4.maleReferralsOut + Region4.femaleReferralsOut;
	}
	
	public void countClientsAvailedOfNX()
	{ 
		List<aggregateResult> referralResults = [select Region__c, count(ID) numclients
			from Contact where id in :clientsAvailOfNX and CreatedDate >= :startOfMonth and CreatedDate <= :endOfMonth group by Region__c];
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.NXClients = (Integer)ar.get('numclients');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.NXClients = (Integer)ar.get('numclients');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.NXClients = (Integer)ar.get('numclients');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.NXClients = (Integer)ar.get('numclients');
			}
		}
	}

	public void countClientsNotAvailedOfNX()
	{ 
		List<aggregateResult> referralResults = [select Region__c, count(ID) numclients
			from Contact where id in :clientsNotAvailOfNX and CreatedDate >= :startOfMonth and CreatedDate <= :endOfMonth group by Region__c];
		for (aggregateResult ar : referralResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.NXNonClients = (Integer)ar.get('numclients');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.NXNonClients = (Integer)ar.get('numclients');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.NXNonClients = (Integer)ar.get('numclients');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.NXNonClients = (Integer)ar.get('numclients');
			}
		}
	}
	
	public void countNXMaterials () // if required, this could be combined with count referrals out, to cut down on SQL calls
	{
		List<aggregateResult> materialsResults = [select Client__r.Region__c, count (ID) sessions,
			sum (Number_of_needles_given_out__c) needlesOut, sum (Needles_returned__c) needlesIn, 
			sum (X2_mls__c) x2mls, sum (X5_mls__c) x5mls, sum (X1ml_single_barrel__c) x1ml, sum (Dibs__c) dibs, sum (Omni_1ml__c) omni, sum (X10_mls__c) x10mls,
			sum (Orange_needles__c) orange, sum (Green_needles__c) green, sum (Blue_needles__c) blue, sum (Brown_needles__c) brown, sum (Baby_Browns__c) babybrown,
			sum (Cook_pots__c) pots, sum (Citric_Water__c) water, sum (Medi_Wipes__c) wipes,  sum(Sharp_bins_distributed__c) binsOut, sum (Sharp_bins_returned__c) binsIn, sum (Tourniquets__c) tourniquets,
			sum (Condoms__c) condoms, sum (Foil_sheets__c) foils
			from Harm_Reduction_NX__c where id in :harmReductionNXMap.keySet() and Date_of_intervention__c >= :startOfMonth group by Client__r.Region__c];
		for (aggregateResult ar : materialsResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.calculateNXMaterialsStats (ar);
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.calculateNXMaterialsStats (ar);
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.calculateNXMaterialsStats (ar);
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.calculateNXMaterialsStats (ar);
			}
		}
		
	}
	
	// this only counts phone events and groups them under "Support phone calls"
	public void countphoneSupportGiven()
	{
		List<aggregateResult> supportResults = [select Region__c, count(ID) support from Event where WhoID in (select ID from Contact where ID in :clientsSupportedThisMonth) and StartDateTime >= :startOfMonth and StartDateTime <= :endOfMonth and Type_of_event__c LIKE '%phone%' group by Region__c];
		for (aggregateResult ar : supportResults)
		{
			if ((String)ar.get('Region__c') == 'Longford')
			{
				Region1.phoneSupportCalls += (Integer)ar.get('support');
			}
			else if ((String)ar.get('Region__c') == 'Westmeath')
			{
				Region2.phoneSupportCalls += (Integer)ar.get('support');
			}
			else if ((String)ar.get('Region__c') == 'Laois')
			{
				Region3.phoneSupportCalls += (Integer)ar.get('support');
			}
			else if ((String)ar.get('Region__c') == 'Offaly')
			{
				Region4.phoneSupportCalls += (Integer)ar.get('support');
			}
		}
	}
	
	public static void createTestObjects ()
	{
		createCountyTestObjects ('Laois');
		createCountyTestObjects ('Longford');
		createCountyTestObjects ('Offaly');
//		createCountyTestObjects ('Westmeath');
	}
	
	public static void createCountyTestObjects (String county)
	{
		Contact cl1 = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c=county,Heroin__c=true, Source_of_referral__c='Self');
		insert cl1;
		Harm_Reduction_NX__c od1 = new Harm_Reduction_NX__c (Client__c = cl1.id, Date_of_intervention__c=Date.newInstance(system.today().year(),system.today().month(),4), Other_MQI_Service__c=true, Cook_pots__c=5);
		od1.Needle_exchange_service_availed_of__c = true;
		insert od1;

		Contact cl2 = new Contact (LastName='Test1', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c=county,Heroin__c=true, Source_of_referral__c='Gardai');
		insert cl2;
		Harm_Reduction_NX__c od2 = new Harm_Reduction_NX__c (Client__c = cl2.id, Date_of_intervention__c=Date.newInstance(system.today().year(),system.today().month(),4), Other_MQI_Service__c=true, Cook_pots__c=5);
		od2.Needles_returned__c = 10;
		od2.Needle_exchange_service_availed_of__c = true;
		insert od2;

		Contact cl3 = new Contact (LastName='Test2', BirthDate=Date.newInstance(1940,1,2), Gender__c='Male',Region__c=county,Heroin__c=true, Source_of_referral__c='Gardai');
		insert cl3;
		Harm_Reduction_NX__c od3 = new Harm_Reduction_NX__c (Client__c = cl3.id, Date_of_intervention__c=Date.newInstance(system.today().year(),system.today().month(),4), Medication_Free_Therapy__c=true, Other_MQI_Service__c=true, Other_Referral_out__c=true, Cook_pots__c=5);
		od3.Needle_exchange_service_availed_of__c = false;
		insert od3;
		
		Harm_Reduction_NX__c od4 = new Harm_Reduction_NX__c (Client__c = cl2.id, Date_of_intervention__c=Date.newInstance(2012,7,4), None__c=true);
		od4.Needle_exchange_service_availed_of__c = false;
		insert od4;
	}
	
	public static testMethod void referralsInTest ()
	{
		NXSummaryData.createTestObjects();
		NXSummaryData msd = new NXSummaryData (Date.newInstance(system.today().year(),system.today().month(),28));

		system.assertEquals (1, msd.Region3.maleReferralsIn);
		system.assertEquals (2, msd.Region3.femaleReferralsIn);
		system.assertEquals (3, msd.Region3.totalReferralsIn);
		system.assertEquals (2, msd.Region3.referralsIn.get('Gardai'));
	}
	
	public static testMethod void referralsOutTest ()
	{
		NXSummaryData.createTestObjects();
		NXSummaryData msd = new NXSummaryData (Date.newInstance(system.today().year(),system.today().month(),28));

		
		system.assertEquals (1, msd.Region3.maleReferralsOut);
		system.assertEquals (2, msd.Region3.femaleReferralsOut);
		system.assertEquals (3, msd.Region3.totalReferralsOut);
		
		system.assertEquals (3, msd.Region1.RefOutAftercareMQIOutreach);
		system.assertEquals (1, msd.Region1.RefOutOtherrefuge);
		system.assertEquals (1, msd.Region1.RefOutMedicationfreetherapy);

//		system.assertEquals (1, msd.Region4.RefOutMedicationfreetherapy);
	}	
	
	public static testMethod void testNXInterventions ()
	{
		NXSummaryData.createTestObjects();
		NXSummaryData msd = new NXSummaryData (Date.newInstance(system.today().year(),system.today().month(),28));

		system.assertEquals (3, msd.clientsNotAvailOfNX.size());
//		system.assertEquals (8, msd.clientsAvailOfNX.size());
		
	}
}