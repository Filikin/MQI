public abstract class MonthSummaryData 
{
	public ReportData Region1 {get;set;}
	public ReportData Region2 {get;set;}
	public ReportData Region3 {get;set;}
	public ReportData Region4 {get;set;}
	
	protected Set<ID>caseLoadClients=new Set<ID>();
	protected Set<ID>clientsSupportedThisMonth;
	public Map<String,Integer> estates {get;set;}
	
	protected Date startOfMonth, endOfMonth, caseLoadStart;
	protected Integer caseLoadPeriod = 60;
	protected MQI_settings__c MQISettings;
	
	void getDefaultSettings ()
	{
		MQISettings = MQI_settings__c.getOrgDefaults();
		if (MQISettings == null)
		{
			MQISettings = new MQI_settings__c (Case_load_period__c=60);
			insert MQISettings;
		}
	}

	public MonthSummaryData (Date eom)
	{
		getDefaultSettings ();
		if (MQISettings.Case_load_period__c != null && MQISettings.Case_load_period__c > 30) caseLoadPeriod = (Integer)MQISettings.Case_load_period__c;
		endOfMonth = eom;
		startOfMonth = Date.newInstance (endOfMonth.year(),endOfMonth.month(),1);
		caseLoadStart = endOfMonth.addDays(-caseLoadPeriod);
		clientsSupportedThisMonth = new Set<ID>();
		estates = new Map<String, Integer>();
		
		Region1 = new ReportData();
		Region2 = new ReportData();
		Region3 = new ReportData();
		Region4 = new ReportData();
	}
	
	public void incrementGenderTotalInRegion (ReportData region, Contact oneClient)
	{
		if (oneClient.Gender__c == 'Male') region.totalMales++;
		else region.totalFemales++;
	}
	
	public void incrementAgeTotalInRegion (ReportData region, Contact oneClient)
	{
		if (oneClient.Age__c == null) region.ageNone++;
		else if (oneClient.Age__c <= 17) region.age1++;
		else if (oneClient.Age__c <= 19) region.age2++;
		else if (oneClient.Age__c <= 24) region.age3++;
		else if (oneClient.Age__c <= 29) region.age4++;
		else if (oneClient.Age__c <= 34) region.age5++;
		else if (oneClient.Age__c <= 39) region.age6++;
		else if (oneClient.Age__c <= 44) region.age7++;
		else if (oneClient.Age__c <= 49) region.age8++;
		else region.age9++;
		region.totalClients++;
	} 
	
	// this list needs to grow
	public void incrementReferralsOutInRegion (ReportData region, Event ev)
	{
		if (ev.Social_and_or_Occupational_reintegration__c) region.RefOutSocialOccupationalreintegration++;
		if (ev.CADS_HSE__c) region.RefOutCADSHSE++;
		if (ev.SIMON_Community__c) region.RefOutSIMONCommunity++;
		if (ev.Aftercare_MQI_MQI_Outreach__c) region.RefOutAftercareMQIOutreach ++;
		if (ev.Traveller_Mediation__c) region.RefOutTravellerMediation ++;
		if (ev.Traveller_Community_Development__c) region.RefOutTravellerCommunityDevelopment ++;
		if (ev.Suicide_Awareness_Officer__c) region.RefOutSuicideAwarenessOfficer ++;
		if (ev.Other_refuge__c) region.RefOutOtherrefuge ++;
		if (ev.Detox_Programme__c) region.RefOutDetoxProgramme ++;
		if (ev.Community_GP__c) region.RefOutCommunityGP ++;
		if (ev.Medication_free_therapy__c) region.RefOutMedicationfreetherapy ++;
		if (ev.Traveller_Health_Unit__c) region.RefOutTravellerHealthUnit ++;
		if (ev.Complimentary_Therapies__c) region.RefOutComplimentaryTherapies ++;
		if (ev.Ana_Liffey_Drug_Project__c) region.RefOutAnaLiffeyDrugProject ++;
		if (ev.Community_Detox__c ) region.RefOutCommunityDetox ++; 
		if (ev.Methadone_Maintenance_Programme__c) region.RefOutMethadone++;
		
	}
	
	public void incrementAdvocacyInRegion (ReportData region, Event ev)
	{
		if (ev.CADS_HSE_Advocacy__c) 
		{
			region.AdvocacyCADSHSEAdvocacy ++;
			region.totalAdvocacy++;
		}
		if (ev.Further_Education__c) 
		{
			region.AdvocacyFurtherEducation ++;
			region.totalAdvocacy++;
		}
		if (ev.Housing__c) 
		{
			region.AdvocacyHousing ++;
			region.totalAdvocacy++;
		}
		if (ev.Other_Clothing__c) 
		{
			region.AdvocacyOtherClothing ++;
			region.totalAdvocacy++;
		}
		if (ev.Prison__c) 
		{
			region.AdvocacyPrison ++;
			region.totalAdvocacy++;
		}
		if (ev.Social_Welfare__c) 
		{
			region.AdvocacySocialWelfare ++;
			region.totalAdvocacy++;
		}
		if (ev.SVDP__c) 
		{
			region.AdvocacySVDP ++;
			region.totalAdvocacy++;
		}
		
	}
	
	public abstract void countNewAttendees ();
	public abstract void countTotalAndAge ();
	public abstract void countClientTypes ();
	public abstract void countPrimaryDrugs ();
	public virtual void countCarePlans (){}
	
	public virtual void countOpenDoorServicesAndReferrals (){}

	public abstract void countReferralsOutTotals ();
	public abstract void countReferralsIn ();
}