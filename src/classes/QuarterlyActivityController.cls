public with sharing class QuarterlyActivityController 
{
	// allow the report to run for half the year - use a parameter on the link - YearHalf=1
	
	public Integer reportingYear {get;set;}
	public Date startDate {get;set;}
	public Date endDate {get;set;}
	public List<MonthSummaryData> monthsData; 
    public List<String> estateList {get;set;}
    public List<String> clientTypeList {get;set;}
    public List<String> primaryDrugList {get;set;}
	public List<String> referralsInList {get;set;}
 	public List<String> supportList {get;set;}
  	public List<String> oneToOneSupportList {get;set;}
	public List<String> one2oneSupportTypeList {get;set;}
	public List<String> interventionTypeList {get;set;}
	public List<String> interventionReasonList {get;set;}
	public List<String> outcomesSelfReportsList {get;set;}
    public List<String> legalStatusList {get;set;}
    public Set<ID>clientsOfThisType;
	
 	public ReportData Totals {get;set;}
	
	public String dataSet;
	
	public QuarterlyActivityController ()
	{
		Integer whichYearQuarter = 0;
		Integer whichYearHalf = System.currentPageReference().getParameters().get('YearHalf')=='1'?1:2;
		String whichYearQuarterString = System.currentPageReference().getParameters().get('YearQuarter');
		if (whichYearQuarterString != null) whichYearQuarter = Integer.valueOf(whichYearQuarterString);

		dataSet = System.currentPageReference().getParameters().get('DataSet');

		String whichYearString = System.currentPageReference().getParameters().get('Year');
		if (whichYearString != null) reportingYear = Integer.valueOf(whichYearString);
		else reportingYear = system.today().year() - 1;
		
		Initialise (reportingYear, whichYearHalf, whichYearQuarter);
	}

	public QuarterlyActivityController (Integer year, Integer whichYearHalf, String whichData)
	{
		dataSet = whichData;
		Initialise (year, whichYearHalf, 0);
	}

	private void Initialise (Integer year, Integer whichHalf, Integer whichQuarter)
	{
		clientsOfThisType = new Set<ID>();
		Map <ID,Contact>clientsMap; 
		
		if (dataSet == 'Rehab')
		{
			clientsMap = new Map<id,contact>([select id from Contact where aftercare_client__c = true]);
			clientsOfThisType = clientsMap.keySet();
		}
		else if (dataSet == 'FamilySupport')
		{
			clientsMap = new Map<id,contact>([select id from Contact where Family_support_client__c = true]);
			clientsOfThisType = clientsMap.keySet();
		}

		Totals = new ReportData ();
		
		Integer startMonth;
		Integer endMonth;
		Integer endDay;
		
		if (whichQuarter > 0)
		{
			startMonth = (whichQuarter * 3) - 2;
			endMonth = whichQuarter * 3;
		}
		else
		{
			startMonth = whichHalf==1 ? 1 : 7;
			endMonth = whichHalf==1 ? 6 : 12;
		}
		endDay = (endMonth == 3 || endMonth == 12) ? 31 : 30;
		
		// in January of current year report on previous year
		//if (system.today().month() == 1 && year == system.today().year()) reportingYear = year - 1;
		reportingYear = year;
		
		startDate = Date.newinstance (reportingYear, startMonth, 1);
		endDate = Date.newinstance (reportingYear, endMonth, endDay);
		
		system.debug ('Year is ' + year);
		system.debug (startDate);
		system.debug (endDate);
		
		if (dataSet == 'OpenDoor') 
		{	
			monthsData = new List<MonthSummaryData>();
			generateEstateList();
		}
		else if (dataSet == 'Traveller')
		{
			monthsData = new List<TravellerMonthlySummaryData>();
			generateSupportList();
		}
		else if (dataSet == 'FamilySupport')
		{
			monthsData = new List<FamilySupportSummaryData>();
			generateSupportList();
			generateOneToOneSupportList();
			generateTypeOfOneToOneSupportList();
		}
		else if (dataSet == 'Rehab')
		{
			monthsData = new List<RehabSummaryData>();
			generateSupportList();
			generateOneToOneSupportList();
			generateTypeOfOneToOneSupportList();
		}
		else if (dataSet == 'NX')
		{
			monthsData = new List<NXSummaryData>();
		}
			
		generateClientTypeList();
		generatePrimaryDrugList();
		generateReferralsInList();	
		generateInterventionTypeList(); 
		generateInterventionReasonList(); 
		generateoutcomesSelfReportsList(); 
		generateLegalStatusList();
	}
	
	public static testMethod void ControllerTest ()
	{
		Integer testYear = (system.today().month() == 1) ? system.today().year()-1 : system.today().year();
		QuarterlyActivityController qac = new QuarterlyActivityController (testYear, 1, 'OpenDoor');
		system.assertEquals (testYear, qac.reportingYear);
		system.assertEquals (Date.newinstance (testYear, 1, 1), qac.startDate);
		system.assertEquals (6, qac.endDate.month());

		QuarterlyActivityController qac2 = new QuarterlyActivityController (testYear, 2, 'OpenDoor');
		system.assertEquals (testYear, qac.reportingYear);
		system.assertEquals (Date.newinstance (testYear, 7, 1), qac2.startDate);
		system.assertEquals (12, qac2.endDate.month());
	}

	public static testMethod void ControllerTest2 ()
	{
		PageReference pageRef = Page.FamilySupportActivityDataPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('YearHalf', '1');
        ApexPages.currentPage().getParameters().put('YearQuarter', '1');
        ApexPages.currentPage().getParameters().put('DataSet', 'FamilySupport');
        ApexPages.currentPage().getParameters().put('Year', '2013');
   
   		QuarterlyActivityController qac = new QuarterlyActivityController ();

        ApexPages.currentPage().getParameters().put('DataSet', 'Rehab');
  		QuarterlyActivityController qac2 = new QuarterlyActivityController ();
  		
  		ApexPages.currentPage().getParameters().put('DataSet', 'Traveller');
  		QuarterlyActivityController qac3 = new QuarterlyActivityController ();
  		
  		ApexPages.currentPage().getParameters().put('DataSet', 'NX');
  		QuarterlyActivityController qac4 = new QuarterlyActivityController ();
	}

	public List<Date> getMonths ()
	{
		List<Date> months = new List<Date>();
		for (Integer i=startDate.month(); i<=endDate.month(); i++)
		{
			months.add (Date.newInstance (reportingYear, i+1, 1).addDays(-1));
			if (dataSet == 'OpenDoor') monthsData.add(new OpenDoorMonthlySummaryData(Date.newInstance (reportingYear, i+1, 1).addDays(-1)));
			else if (dataSet == 'Traveller') monthsData.add(new TravellerMonthlySummaryData(Date.newInstance (reportingYear, i+1, 1).addDays(-1)));
			else if (dataSet == 'FamilySupport') monthsData.add(new FamilySupportSummaryData(Date.newInstance (reportingYear, i+1, 1).addDays(-1), clientsOfThisType));
			else if (dataSet == 'Rehab') monthsData.add(new RehabSummaryData(Date.newInstance (reportingYear, i+1, 1).addDays(-1), clientsOfThisType));
			else monthsData.add(new NXSummaryData(Date.newInstance (reportingYear, i+1, 1).addDays(-1)));
		}
		calculateTotals();
		return months;
	}
	
	public void calculateTotals()
	{
		for (MonthSummaryData oneMonth: monthsData)
		{
			Totals.newMales += oneMonth.Region1.newMales + oneMonth.Region2.newMales + oneMonth.Region3.newMales + oneMonth.Region4.newMales;
			Totals.newFemales += oneMonth.Region1.newFemales + oneMonth.Region2.newFemales + oneMonth.Region3.newFemales + oneMonth.Region4.newFemales;
/*			Totals.totalMales += oneMonth.Region1.totalMales + oneMonth.Region2.totalMales + oneMonth.Region3.totalMales + oneMonth.Region4.totalMales;
			Totals.totalFemales += oneMonth.Region1.totalFemales + oneMonth.Region2.totalFemales + oneMonth.Region3.totalFemales + oneMonth.Region4.totalFemales;
			Totals.ageNone += oneMonth.Region1.ageNone + oneMonth.Region2.ageNone + oneMonth.Region3.ageNone + oneMonth.Region4.ageNone;
			Totals.age1 += oneMonth.Region1.age1 + oneMonth.Region2.age1 + oneMonth.Region3.age1 + oneMonth.Region4.age1;
			Totals.age2 += oneMonth.Region1.age2 + oneMonth.Region2.age2 + oneMonth.Region3.age2 + oneMonth.Region4.age2;
			Totals.age3 += oneMonth.Region1.age3 + oneMonth.Region2.age3 + oneMonth.Region3.age3 + oneMonth.Region4.age3;
			Totals.age4 += oneMonth.Region1.age4 + oneMonth.Region2.age4 + oneMonth.Region3.age4 + oneMonth.Region4.age4;
			Totals.age5 += oneMonth.Region1.age5 + oneMonth.Region2.age5 + oneMonth.Region3.age5 + oneMonth.Region4.age5;
			Totals.age6 += oneMonth.Region1.age6 + oneMonth.Region2.age6 + oneMonth.Region3.age6 + oneMonth.Region4.age6;
			Totals.age7 += oneMonth.Region1.age7 + oneMonth.Region2.age7 + oneMonth.Region3.age7 + oneMonth.Region4.age7;
			Totals.age8 += oneMonth.Region1.age8 + oneMonth.Region2.age8 + oneMonth.Region3.age8 + oneMonth.Region4.age8;
			Totals.age9 += oneMonth.Region1.age9 + oneMonth.Region2.age9 + oneMonth.Region3.age9 + oneMonth.Region4.age9;
*/			
			Totals.One2One += oneMonth.Region1.One2One + oneMonth.Region2.One2One + oneMonth.Region3.One2One + oneMonth.Region4.One2One;
//			Totals.one2oneClients += oneMonth.Region1.one2oneClients + oneMonth.Region2.one2oneClients + oneMonth.Region3.one2oneClients + oneMonth.Region4.one2oneClients;
			Totals.phoneSupportCalls += oneMonth.Region1.phoneSupportCalls + oneMonth.Region2.phoneSupportCalls + oneMonth.Region3.phoneSupportCalls + oneMonth.Region4.phoneSupportCalls;
			Totals.familySupportSessions += oneMonth.Region1.familySupportSessions + oneMonth.Region2.familySupportSessions + oneMonth.Region3.familySupportSessions + oneMonth.Region4.familySupportSessions;
			Totals.FamilySupportGroupSessions += oneMonth.Region1.FamilySupportGroupSessions + oneMonth.Region2.FamilySupportGroupSessions + oneMonth.Region3.FamilySupportGroupSessions + oneMonth.Region4.FamilySupportGroupSessions;
			Totals.FamilySupportGroupClients += oneMonth.Region1.FamilySupportGroupClients + oneMonth.Region2.FamilySupportGroupClients + oneMonth.Region3.FamilySupportGroupClients + oneMonth.Region4.FamilySupportGroupClients;
			Totals.NewFamilySupportGroups += oneMonth.Region1.NewFamilySupportGroups + oneMonth.Region2.NewFamilySupportGroups + oneMonth.Region3.NewFamilySupportGroups + oneMonth.Region4.NewFamilySupportGroups;
			Totals.ClosedFamilySupportGroups += oneMonth.Region1.ClosedFamilySupportGroups + oneMonth.Region2.ClosedFamilySupportGroups + oneMonth.Region3.ClosedFamilySupportGroups + oneMonth.Region4.ClosedFamilySupportGroups;
			Totals.NewFamilySupportGroupClients += oneMonth.Region1.NewFamilySupportGroupClients + oneMonth.Region2.NewFamilySupportGroupClients + oneMonth.Region3.NewFamilySupportGroupClients + oneMonth.Region4.NewFamilySupportGroupClients;
			Totals.AftercareSupportGroupSessions += oneMonth.Region1.AftercareSupportGroupSessions + oneMonth.Region2.AftercareSupportGroupSessions + oneMonth.Region3.AftercareSupportGroupSessions + oneMonth.Region4.AftercareSupportGroupSessions;
			Totals.AftercareSupportGroupClients += oneMonth.Region1.AftercareSupportGroupClients + oneMonth.Region2.AftercareSupportGroupClients + oneMonth.Region3.AftercareSupportGroupClients + oneMonth.Region4.AftercareSupportGroupClients;

			Totals.CarePlansInPlace += oneMonth.Region1.CarePlansInPlace + oneMonth.Region2.CarePlansInPlace;
			Totals.CarePlansCreated += oneMonth.Region1.CarePlansCreated + oneMonth.Region2.CarePlansCreated;
			Totals.CarePlansReviewed += oneMonth.Region1.CarePlansReviewed + oneMonth.Region2.CarePlansReviewed;
			Totals.CarePlansCompleted += oneMonth.Region1.CarePlansCompleted + oneMonth.Region2.CarePlansCompleted;
			
			Totals.maleReferralsIn +=  oneMonth.Region1.maleReferralsIn + oneMonth.Region2.maleReferralsIn + oneMonth.Region3.maleReferralsIn + oneMonth.Region4.maleReferralsIn;
			Totals.femaleReferralsIn +=  oneMonth.Region1.femaleReferralsIn + oneMonth.Region2.femaleReferralsIn + oneMonth.Region3.femaleReferralsIn + oneMonth.Region4.femaleReferralsIn;
			Totals.maleReferralsOut +=  oneMonth.Region1.maleReferralsOut + oneMonth.Region2.maleReferralsOut + oneMonth.Region3.maleReferralsOut + oneMonth.Region4.maleReferralsOut;
			Totals.femaleReferralsOut +=  oneMonth.Region1.femaleReferralsOut + oneMonth.Region2.femaleReferralsOut + oneMonth.Region3.femaleReferralsOut + oneMonth.Region4.femaleReferralsOut;
			
			Totals.RefOutSocialOccupationalreintegration += oneMonth.Region1.RefOutSocialOccupationalreintegration + oneMonth.Region2.RefOutSocialOccupationalreintegration;
			Totals.RefOutCADSHSE += oneMonth.Region1.RefOutCADSHSE + oneMonth.Region2.RefOutCADSHSE;
			Totals.RefOutSIMONCommunity  += oneMonth.Region1.RefOutSIMONCommunity  + oneMonth.Region2.RefOutSIMONCommunity ;
			Totals.RefOutAftercareMQIOutreach  += oneMonth.Region1.RefOutAftercareMQIOutreach  + oneMonth.Region2.RefOutAftercareMQIOutreach ;
			Totals.RefOutTravellerMediation  += oneMonth.Region1.RefOutTravellerMediation  + oneMonth.Region2.RefOutTravellerMediation ;
			Totals.RefOutTravellerCommunityDevelopment  += oneMonth.Region1.RefOutTravellerCommunityDevelopment  + oneMonth.Region2.RefOutTravellerCommunityDevelopment ;
			Totals.RefOutSuicideAwarenessOfficer  += oneMonth.Region1.RefOutSuicideAwarenessOfficer  + oneMonth.Region2.RefOutSuicideAwarenessOfficer ;
			Totals.RefOutOtherrefuge  += oneMonth.Region1.RefOutOtherrefuge  + oneMonth.Region2.RefOutOtherrefuge ;
			Totals.RefOutDetoxProgramme  += oneMonth.Region1.RefOutDetoxProgramme  + oneMonth.Region2.RefOutDetoxProgramme ;
			Totals.RefOutCommunityGP  += oneMonth.Region1.RefOutCommunityGP  + oneMonth.Region2.RefOutCommunityGP + oneMonth.Region3.RefOutCommunityGP  + oneMonth.Region4.RefOutCommunityGP ;
			Totals.RefOutMedicationfreetherapy  += oneMonth.Region1.RefOutMedicationfreetherapy  + oneMonth.Region2.RefOutMedicationfreetherapy + oneMonth.Region3.RefOutMedicationfreetherapy  + oneMonth.Region4.RefOutMedicationfreetherapy;
			Totals.RefOutTravellerHealthUnit  += oneMonth.Region1.RefOutTravellerHealthUnit  + oneMonth.Region2.RefOutTravellerHealthUnit ;
			Totals.RefOutComplimentaryTherapies  += oneMonth.Region1.RefOutComplimentaryTherapies  + oneMonth.Region2.RefOutComplimentaryTherapies ;
			Totals.RefOutAnaLiffeyDrugProject  += oneMonth.Region1.RefOutAnaLiffeyDrugProject  + oneMonth.Region2.RefOutAnaLiffeyDrugProject ;
			Totals.RefOutCommunityDetox   += oneMonth.Region1.RefOutCommunityDetox   + oneMonth.Region2.RefOutCommunityDetox  ;
			Totals.RefOutMethadone  += oneMonth.Region1.RefOutMethadone  + oneMonth.Region2.RefOutMethadone + oneMonth.Region3.RefOutMethadone  + oneMonth.Region4.RefOutMethadone;

			Totals.OtherMQIService  += oneMonth.Region1.OtherMQIService  + oneMonth.Region2.OtherMQIService + oneMonth.Region3.OtherMQIService  + oneMonth.Region4.OtherMQIService;
			
			Totals.RefOutChildren  += oneMonth.Region1.RefOutChildren  + oneMonth.Region2.RefOutChildren + oneMonth.Region3.RefOutChildren  + oneMonth.Region4.RefOutChildren;
			Totals.RefOutMidlands  += oneMonth.Region1.RefOutMidlands  + oneMonth.Region2.RefOutMidlands + oneMonth.Region3.RefOutMidlands  + oneMonth.Region4.RefOutMidlands;
			Totals.RefOutYouth  += oneMonth.Region1.RefOutYouth  + oneMonth.Region2.RefOutYouth + oneMonth.Region3.RefOutYouth  + oneMonth.Region4.RefOutYouth;
			Totals.RefOutMABs  += oneMonth.Region1.RefOutMABs  + oneMonth.Region2.RefOutMABs + oneMonth.Region3.RefOutMABs  + oneMonth.Region4.RefOutMABs;
			Totals.RefOutFamilySupport  += oneMonth.Region1.RefOutFamilySupport  + oneMonth.Region2.RefOutFamilySupport + oneMonth.Region3.RefOutFamilySupport  + oneMonth.Region4.RefOutFamilySupport;
			Totals.RefOutFamilyResource  += oneMonth.Region1.RefOutFamilyResource  + oneMonth.Region2.RefOutFamilyResource + oneMonth.Region3.RefOutFamilyResource  + oneMonth.Region4.RefOutFamilyResource;
			Totals.RefOutFamilyMediation  += oneMonth.Region1.RefOutFamilyMediation  + oneMonth.Region2.RefOutFamilyMediation + oneMonth.Region3.RefOutFamilyMediation  + oneMonth.Region4.RefOutFamilyMediation;
			Totals.RefOutFamilyTherapist  += oneMonth.Region1.RefOutFamilyTherapist  + oneMonth.Region2.RefOutFamilyTherapist + oneMonth.Region3.RefOutFamilyTherapist  + oneMonth.Region4.RefOutFamilyTherapist;
			Totals.RefOutCounselling  += oneMonth.Region1.RefOutCounselling  + oneMonth.Region2.RefOutCounselling + oneMonth.Region3.RefOutCounselling  + oneMonth.Region4.RefOutCounselling;
		
			Totals.AdvocacyCADSHSEAdvocacy  += oneMonth.Region1.AdvocacyCADSHSEAdvocacy  + oneMonth.Region2.AdvocacyCADSHSEAdvocacy + oneMonth.Region3.AdvocacyCADSHSEAdvocacy  + oneMonth.Region4.AdvocacyCADSHSEAdvocacy ;
			Totals.AdvocacyFurtherEducation  += oneMonth.Region1.AdvocacyFurtherEducation  + oneMonth.Region2.AdvocacyFurtherEducation + oneMonth.Region3.AdvocacyFurtherEducation  + oneMonth.Region4.AdvocacyFurtherEducation;
			Totals.AdvocacyHousing  += oneMonth.Region1.AdvocacyHousing  + oneMonth.Region2.AdvocacyHousing + oneMonth.Region3.AdvocacyHousing  + oneMonth.Region4.AdvocacyHousing;
			Totals.AdvocacyOtherClothing  += oneMonth.Region1.AdvocacyOtherClothing  + oneMonth.Region2.AdvocacyOtherClothing + oneMonth.Region3.AdvocacyOtherClothing  + oneMonth.Region4.AdvocacyOtherClothing;
			Totals.AdvocacyPrison  += oneMonth.Region1.AdvocacyPrison  + oneMonth.Region2.AdvocacyPrison + oneMonth.Region3.AdvocacyPrison  + oneMonth.Region4.AdvocacyPrison;
			Totals.AdvocacySocialWelfare  += oneMonth.Region1.AdvocacySocialWelfare  + oneMonth.Region2.AdvocacySocialWelfare + oneMonth.Region3.AdvocacySocialWelfare  + oneMonth.Region4.AdvocacySocialWelfare;
			Totals.AdvocacySVDP  += oneMonth.Region1.AdvocacySVDP  + oneMonth.Region2.AdvocacySVDP + oneMonth.Region3.AdvocacySVDP  + oneMonth.Region4.AdvocacySVDP;
			Totals.totalAdvocacy  += oneMonth.Region1.totalAdvocacy  + oneMonth.Region2.totalAdvocacy + oneMonth.Region3.totalAdvocacy  + oneMonth.Region4.totalAdvocacy;
			
			// Only needed for NX
			if (dataSet == 'NX')
			{
				Totals.NXSessions  += oneMonth.Region1.NXSessions  + oneMonth.Region2.NXSessions + oneMonth.Region3.NXSessions  + oneMonth.Region4.NXSessions;
				Totals.NXClients  += oneMonth.Region1.NXClients  + oneMonth.Region2.NXClients + oneMonth.Region3.NXClients  + oneMonth.Region4.NXClients;
				Totals.NXNonClients  += oneMonth.Region1.NXNonClients  + oneMonth.Region2.NXNonClients + oneMonth.Region3.NXNonClients  + oneMonth.Region4.NXNonClients;
				Totals.NXNewClients  += oneMonth.Region1.NXNewClients  + oneMonth.Region2.NXNewClients + oneMonth.Region3.NXNewClients  + oneMonth.Region4.NXNewClients;
				Totals.NX10mls  += oneMonth.Region1.NX10mls  + oneMonth.Region2.NX10mls + oneMonth.Region3.NX10mls  + oneMonth.Region4.NX10mls;
				Totals.NX5mls  += oneMonth.Region1.NX5mls  + oneMonth.Region2.NX5mls + oneMonth.Region3.NX5mls  + oneMonth.Region4.NX5mls;
				Totals.NX2mls  += oneMonth.Region1.NX2mls  + oneMonth.Region2.NX2mls + oneMonth.Region3.NX2mls  + oneMonth.Region4.NX2mls;
				Totals.NXDibs  += oneMonth.Region1.NXDibs  + oneMonth.Region2.NXDibs + oneMonth.Region3.NXDibs  + oneMonth.Region4.NXDibs;
				Totals.NXMonojets  += oneMonth.Region1.NXMonojets  + oneMonth.Region2.NXMonojets + oneMonth.Region3.NXMonojets  + oneMonth.Region4.NXMonojets;
				Totals.NX1mls  += oneMonth.Region1.NX1mls  + oneMonth.Region2.NX1mls + oneMonth.Region3.NX1mls  + oneMonth.Region4.NX1mls;
				Totals.NXOranges  += oneMonth.Region1.NXOranges  + oneMonth.Region2.NXOranges + oneMonth.Region3.NXOranges  + oneMonth.Region4.NXOranges;
				Totals.NXBrowns  += oneMonth.Region1.NXBrowns  + oneMonth.Region2.NXBrowns + oneMonth.Region3.NXBrowns  + oneMonth.Region4.NXBrowns;
				Totals.NXBlues  += oneMonth.Region1.NXBlues  + oneMonth.Region2.NXBlues + oneMonth.Region3.NXBlues  + oneMonth.Region4.NXBlues;
				Totals.NXGreens  += oneMonth.Region1.NXGreens  + oneMonth.Region2.NXGreens + oneMonth.Region3.NXGreens  + oneMonth.Region4.NXGreens;
				Totals.NXNeedlesOut  += oneMonth.Region1.NXNeedlesOut  + oneMonth.Region2.NXNeedlesOut + oneMonth.Region3.NXNeedlesOut  + oneMonth.Region4.NXNeedlesOut;
				Totals.NXNeedlesIn  += oneMonth.Region1.NXNeedlesIn  + oneMonth.Region2.NXNeedlesIn + oneMonth.Region3.NXNeedlesIn  + oneMonth.Region4.NXNeedlesIn;
				Totals.NXSharpBinsOut  += oneMonth.Region1.NXSharpBinsOut  + oneMonth.Region2.NXSharpBinsOut + oneMonth.Region3.NXSharpBinsOut  + oneMonth.Region4.NXSharpBinsOut;
				Totals.NXSharpBinsIn  += oneMonth.Region1.NXSharpBinsIn  + oneMonth.Region2.NXSharpBinsIn + oneMonth.Region3.NXSharpBinsIn  + oneMonth.Region4.NXSharpBinsIn;
				Totals.NXCondoms  += oneMonth.Region1.NXCondoms  + oneMonth.Region2.NXCondoms + oneMonth.Region3.NXCondoms  + oneMonth.Region4.NXCondoms;
				Totals.NXCookpots  += oneMonth.Region1.NXCookpots  + oneMonth.Region2.NXCookpots + oneMonth.Region3.NXCookpots  + oneMonth.Region4.NXCookpots;
				Totals.NXFoilSheets  += oneMonth.Region1.NXFoilSheets  + oneMonth.Region2.NXFoilSheets + oneMonth.Region3.NXFoilSheets  + oneMonth.Region4.NXFoilSheets;
			}
		}
		countUniqueClients();
		Totals.newAttendees = Totals.newMales + Totals.newFemales;
		Totals.totalClients = Totals.totalMales + Totals.totalFemales;
		Totals.totalReferralsIn = Totals.maleReferralsIn + Totals.femaleReferralsIn;
		Totals.totalReferralsOut = Totals.maleReferralsOut + Totals.femaleReferralsOut;
		
	}
	
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

	public void countUniqueClients()
	{
		Integer caseLoadPeriod = 60;
		getDefaultSettings ();
		if (MQISettings.Case_load_period__c != null && MQISettings.Case_load_period__c > 30) caseLoadPeriod = (Integer)MQISettings.Case_load_period__c;
		Date endOfYear = Date.newInstance (reportingYear, 12, 31);
		Date startOfYear = Date.newInstance (reportingYear, 1, 1).addDays (-caseLoadPeriod);

		Set<ID>clientsSupportedThisYear = new Set<ID>();
		Set<ID>clientsOneToOneSupportThisYear = new Set<ID>();
		Totals.one2oneClients = 0;
		if (dataSet == 'NX')
		{
			Map <ID, Harm_Reduction_NX__c> harmReductionNXMap = new Map <ID, Harm_Reduction_NX__c> ([select Client__c
				from Harm_Reduction_NX__c where Date_of_intervention__c >= :startOfYear and Date_of_intervention__c <= :endOfYear]);
				
			for (Harm_Reduction_NX__c oneEvent: harmReductionNXMap.values())
			{
				clientsSupportedThisYear.add(oneEvent.Client__c);
			}
		}
		else if (dataSet == 'OpenDoor')
		{
			Map <ID, Open_Door_attendance__c> openDoorMap = new Map <ID, Open_Door_attendance__c> ([select Client__c
				from Open_Door_attendance__c where Date_of_attendance__c >= :startOfYear and Date_of_attendance__c <= :endOfYear]);
				
			for (Open_Door_attendance__c oneEvent: openDoorMap.values())
			{
				clientsSupportedThisYear.add(oneEvent.Client__c);
			}
		}
		else
		{
			for (Event oneEvent: [select WhoID, None__c, Days_since_last_activity__c, Type_of_event__c, StartDateTime from Event where StartDateTime >= :startOfYear and StartDateTime < :endOfYear and whoid in :clientsOfThisType])
			{
				system.debug ('Event: ' + oneEvent);
				clientsSupportedThisYear.add(oneEvent.WhoID);
				if (oneEvent.Type_of_event__c == 'One to one support') clientsOneToOneSupportThisYear.add (oneEvent.WhoID);
			}
		}
		
		List<Contact> clients = [select Age__c, Gender__c, Type_of_client__c, Primary_Drug_Use__c from Contact where id in :clientsSupportedThisYear];
		for (Contact oneClient : clients)
		{
			system.debug ('Count: ' + Totals.clientTypes.get(oneClient.Type_of_client__c));
			try
			{
				if (Totals.clientTypes.get(oneClient.Type_of_client__c) == null) Totals.clientTypes.put (oneClient.Type_of_client__c, 1);
				else Totals.clientTypes.put (oneClient.Type_of_client__c, Totals.clientTypes.get(oneClient.Type_of_client__c)+1);

				if (Totals.primaryDrugTypes.get(oneClient.Primary_Drug_Use__c) == null) Totals.primaryDrugTypes.put (oneClient.Primary_Drug_Use__c, 1);
				else Totals.primaryDrugTypes.put (oneClient.Primary_Drug_Use__c, Totals.primaryDrugTypes.get(oneClient.Primary_Drug_Use__c)+1);
			}
			catch (Exception e){}
			if (oneClient.Gender__c == 'Male') Totals.totalMales++;
			else Totals.totalFemales++;

			if (oneClient.Age__c == null) Totals.ageNone++;
			else if (oneClient.Age__c <= 17) Totals.age1++;
			else if (oneClient.Age__c <= 19) Totals.age2++;
			else if (oneClient.Age__c <= 24) Totals.age3++;
			else if (oneClient.Age__c <= 29) Totals.age4++;
			else if (oneClient.Age__c <= 34) Totals.age5++;
			else if (oneClient.Age__c <= 39) Totals.age6++;
			else if (oneClient.Age__c <= 44) Totals.age7++;
			else if (oneClient.Age__c <= 49) Totals.age8++;
			else Totals.age9++;
			
			if (clientsOneToOneSupportThisYear.contains (oneClient.id)) Totals.one2oneClients++;
		}
	}
	
	public void generateEstateList() 
 	{
 		estateList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Contact.Estate__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			estateList.add(pleOptions.getLabel());
		}
		estateList.add ('Not specified');
  	}
	
	public void generateSupportList() 
 	{
 		supportList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Event.Type_of_Event__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			supportList.add(pleOptions.getLabel());
		}
		supportList.add ('Not specified');
  	}
	
	public void generateOneToOneSupportList() 
 	{
 		onetooneSupportList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Event.Reason_for_support__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			onetooneSupportList.add(pleOptions.getLabel());
		}
		onetooneSupportList.add ('Not specified');
  	}
	
	public void generateTypeOfOneToOneSupportList() 
 	{
 		one2oneSupportTypeList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Event.Type_of_One_to_one_support__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			one2oneSupportTypeList.add(pleOptions.getLabel());
		}
		one2oneSupportTypeList.add ('Not specified');
  	}

	public void generateInterventionReasonList() 
 	{
 		interventionReasonList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Event.Type_of_event__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			if (pleOptions.getLabel().contains('intervention') || pleOptions.getLabel().contains('One to one')) interventionReasonList.add(pleOptions.getLabel());
		}
  	}

	public void generateClientTypeList() 
 	{
 		clientTypeList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Contact.Type_of_client__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			clientTypeList.add(pleOptions.getLabel());
		}
  	}

	public void generatePrimaryDrugList() 
 	{
 		primaryDrugList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Contact.Primary_Drug_Use__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			primaryDrugList.add(pleOptions.getLabel());
		}
  	}

	public void generateLegalStatusList() 
 	{
 		legalStatusList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Contact.Legal_Status__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			legalStatusList.add(pleOptions.getLabel());
		}
  	}

	public void generateInterventionTypeList() 
 	{
 		interventionTypeList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Harm_Reduction_NX__c.Type_of_Intervention__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			interventionTypeList.add(pleOptions.getLabel());
		}
  	}

	public void generateOutcomesSelfReportsList() 
 	{
 		outcomesSelfReportsList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Harm_Reduction_NX__c.Outcomes_Self_Report__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			outcomesSelfReportsList.add(pleOptions.getLabel());
		}
  	}

	public String getEstateDetails ()
	{
		String result='';
		Integer estateCount;
		for (String oneEstate: estateList)
		{
			result += oneEstate;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.estates.get(oneEstate) == null) estateCount = 0;
				else estateCount = oneMonth.estates.get(oneEstate); 
				result += ',' + estateCount;
			}
			result += '\n';
		}
		return result;	
	}
	
	public String getSupportDetails ()
	{
		String result='';
		Integer supportCount;
		Integer supportCountTotal;
		for (String oneSupport: supportList)
		{
			supportCountTotal = 0;
			result += oneSupport;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.supports.get(oneSupport) == null) supportCount = 0;
				else supportCount = oneMonth.Region1.supports.get(oneSupport); 
				result += ',' + supportCount;
				supportCountTotal += supportCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.supports.get(oneSupport) == null) supportCount = 0;
					else supportCount = oneMonth.Region2.supports.get(oneSupport); 
					result += ',' + supportCount;
					supportCountTotal += supportCount;
				}
				if (dataSet == 'FamilySupport')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.supports.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region3.supports.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.supports.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region4.supports.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
				}
				result += ',' + supportCountTotal;
			}
			result += '\n';
		}
		return result;	
	}
	
	public String getOneToOneSupportDetails ()
	{
		String result='';
		Integer supportCount;
		Integer supportCountTotal;
		for (String oneSupport: onetooneSupportList)
		{
			supportCountTotal = 0;
			result += oneSupport;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.supports.get(oneSupport) == null) supportCount = 0;
				else supportCount = oneMonth.Region1.supports.get(oneSupport); 
				result += ',' + supportCount;
				supportCountTotal += supportCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.supports.get(oneSupport) == null) supportCount = 0;
					else supportCount = oneMonth.Region2.supports.get(oneSupport); 
					result += ',' + supportCount;
					supportCountTotal += supportCount;
				}
				if (dataSet == 'FamilySupport')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.supports.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region3.supports.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.supports.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region4.supports.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
				}
				result += ',' + supportCountTotal;
			}
			result += '\n';
		}
		return result;	
	}
	
	public String getPhoneSupportDetails ()
	{
		String result='';
		Integer supportCount;
		Integer supportCountTotal;
		for (String oneSupport: onetooneSupportList)
		{
			supportCountTotal = 0;
			result += oneSupport;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.phoneSupportReasons.get(oneSupport) == null) supportCount = 0;
				else supportCount = oneMonth.Region1.phoneSupportReasons.get(oneSupport); 
				result += ',' + supportCount;
				supportCountTotal += supportCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.phoneSupportReasons.get(oneSupport) == null) supportCount = 0;
					else supportCount = oneMonth.Region2.phoneSupportReasons.get(oneSupport); 
					result += ',' + supportCount;
					supportCountTotal += supportCount;
				}
				if (dataSet == 'FamilySupport')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.phoneSupportReasons.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region3.phoneSupportReasons.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.phoneSupportReasons.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region4.phoneSupportReasons.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
				}
				result += ',' + supportCountTotal;
			}
			result += '\n';
		}
		return result;	
	}
	
	public String getTypeOfOnetoOneSupportDetails ()
	{
		String result='';
		Integer supportCount;
		Integer supportCountTotal;
		for (String oneSupport: one2oneSupportTypeList)
		{
			supportCountTotal = 0;
			result += oneSupport;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.one2onesupporttypes.get(oneSupport) == null) supportCount = 0;
				else supportCount = oneMonth.Region1.one2onesupporttypes.get(oneSupport); 
				result += ',' + supportCount;
				supportCountTotal += supportCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.one2onesupporttypes.get(oneSupport) == null) supportCount = 0;
					else supportCount = oneMonth.Region2.one2onesupporttypes.get(oneSupport); 
					result += ',' + supportCount;
					supportCountTotal += supportCount;
				}
				if (dataSet == 'FamilySupport')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.one2onesupporttypes.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region3.one2onesupporttypes.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.one2onesupporttypes.get(oneSupport) == null) supportCount = 0;
						else supportCount = oneMonth.Region4.one2onesupporttypes.get(oneSupport); 
						result += ',' + supportCount;
						supportCountTotal += supportCount;
					}
				}
				result += ',' + supportCountTotal;
			}
			result += '\n';
		}
		return result;	
	}

	public String getClientTypeDetails ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: clientTypeList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.clientTypes.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.clientTypes.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport' || dataSet == 'NX' || dataSet == 'Rehab')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.clientTypes.get(oneType) == null) typeCount = 0;
					else typeCount = oneMonth.Region2.clientTypes.get(oneType); 
					result += ',' + typeCount;
					typeCountTotal += typeCount;
				}

				if (dataSet == 'FamilySupport' || dataSet == 'NX' || dataSet == 'Rehab')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.clientTypes.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region3.clientTypes.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.clientTypes.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region4.clientTypes.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
				}
			}
			result += ',';
			result += Totals.clientTypes.get(oneType) == null ? 0 : Totals.clientTypes.get(oneType);
			result += '\n';
		}
		return result;	
	}
	
	public String getPrimaryDrugDetails ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: primaryDrugList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.primaryDrugTypes.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.primaryDrugTypes.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport'|| dataSet == 'NX' || dataSet == 'Rehab')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.primaryDrugTypes.get(oneType) == null) typeCount = 0;
					else typeCount = oneMonth.Region2.primaryDrugTypes.get(oneType); 
					result += ',' + typeCount;
					typeCountTotal += typeCount;
				}
				if (dataSet == 'FamilySupport' || dataSet == 'NX' || dataSet == 'Rehab')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.primaryDrugTypes.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region3.primaryDrugTypes.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.primaryDrugTypes.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region4.primaryDrugTypes.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
				}
				result += ',';
				result += Totals.primaryDrugTypes.get(oneType) == null ? 0 : Totals.primaryDrugTypes.get(oneType);
			}
			result += '\n';
		}
		return result;	
	}

	public String getLegalStatusDetails ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: legalStatusList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.legalStatuses.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.legalStatuses.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport'|| dataSet == 'NX' || dataSet == 'Rehab')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.legalStatuses.get(oneType) == null) typeCount = 0;
					else typeCount = oneMonth.Region2.legalStatuses.get(oneType); 
					result += ',' + typeCount;
					typeCountTotal += typeCount;
				}
				if (dataSet == 'FamilySupport' || dataSet == 'NX' || dataSet == 'Rehab')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.legalStatuses.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region3.legalStatuses.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.legalStatuses.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region4.legalStatuses.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
				}
				result += ',' + typeCountTotal;
			}
			result += '\n';
		}
		return result;	
	}

	public String getInterventionReasons ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: interventionReasonList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.interventionReasons.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.interventionReasons.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region2.interventionReasons.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region2.interventionReasons.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region3.interventionReasons.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region3.interventionReasons.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region4.interventionReasons.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region4.interventionReasons.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			result += ',' + typeCountTotal;
			result += '\n';
		}
		return result;	
	}
	
	public String getInterventionTypeDetails ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: interventionTypeList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.interventionTypes.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.interventionTypes.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region2.interventionTypes.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region2.interventionTypes.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region3.interventionTypes.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region3.interventionTypes.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region4.interventionTypes.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region4.interventionTypes.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			result += ',' + typeCountTotal;
			result += '\n';
		}
		return result;	
	}

	public String getOutcomesSelfReportDetails ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: outcomesSelfReportsList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.outcomesSelfReports.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.outcomesSelfReports.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region2.outcomesSelfReports.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region2.outcomesSelfReports.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region3.outcomesSelfReports.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region3.outcomesSelfReports.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region4.outcomesSelfReports.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region4.outcomesSelfReports.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			result += ',' + typeCountTotal;
			result += '\n';
		}
		return result;	
	}

	public void generateReferralsInList() 
 	{
 		referralsInList = new List<String>();
    	Schema.DescribeFieldResult optionFieldDescription = Contact.Source_of_Referral__c.getDescribe();
		for(Schema.PicklistEntry pleOptions : optionFieldDescription.getPicklistValues())
		{
 			referralsInList.add(pleOptions.getLabel());
		}
  	}

	public String getreferralsInDetails ()
	{
		String result='';
		Integer typeCount;
		Integer typeCountTotal;
		for (String oneType: referralsInList)
		{
			typeCountTotal = 0;
			result += oneType;
			for (MonthSummaryData oneMonth: monthsData)
			{
				if (oneMonth.Region1.referralsIn.get(oneType) == null) typeCount = 0;
				else typeCount = oneMonth.Region1.referralsIn.get(oneType); 
				result += ',' + typeCount;
				typeCountTotal += typeCount;
			}
			if (dataSet == 'Traveller' || dataSet == 'FamilySupport' || dataSet == 'NX' || dataSet == 'Rehab')
			{
				for (MonthSummaryData oneMonth: monthsData)
				{
					if (oneMonth.Region2.referralsIn.get(oneType) == null) typeCount = 0;
					else typeCount = oneMonth.Region2.referralsIn.get(oneType); 
					result += ',' + typeCount;
					typeCountTotal += typeCount;
				}
				if (dataSet == 'FamilySupport' || dataSet == 'NX' || dataSet == 'Rehab')
				{
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region3.referralsIn.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region3.referralsIn.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
					for (MonthSummaryData oneMonth: monthsData)
					{
						if (oneMonth.Region4.referralsIn.get(oneType) == null) typeCount = 0;
						else typeCount = oneMonth.Region4.referralsIn.get(oneType); 
						result += ',' + typeCount;
						typeCountTotal += typeCount;
					}
				}
				result += ',' + typeCountTotal;
			}
			result += '\n';
		}
		return result;
	}
	
	public static testMethod void monthTest1 ()
	{
		QuarterlyActivityController qac = new QuarterlyActivityController (2011,1, 'OpenDoor');
		List<Date> months = qac.getMonths();
		system.assertEquals (3, months[2].month());
		system.assertEquals (6, months.size());
	}
	
	public static testMethod void monthTest2 ()
	{
		QuarterlyActivityController qac2 = new QuarterlyActivityController (2011,2, 'OpenDoor');
		List<Date>months = qac2.getMonths();
		system.assertEquals (9, months[2].month());
		system.assertEquals (6, months.size());
	}
	
	public List<MonthSummaryData> getMonthData ()
	{
		return monthsData;
	}
	
	//Tests
	public static testMethod void getBitsTest ()
	{
		Contact cl = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true);
		cl.Primary_Drug_Use__c = 'Cocaine';
		cl.Type_of_client__c = 'Homeless drug user';
		insert cl;
		
		Open_Door_attendance__c od1 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,7,4), None__c=true, Days_since_last_activity__c=70);
		insert od1;
		
		QuarterlyActivityController qac = new QuarterlyActivityController (2012,2, 'OpenDoor');
		List<Date> months = qac.getMonths();
		system.assertEquals (6, months.size());
		qac.getEstateDetails ();
		qac.getClientTypeDetails();
		qac.getPrimaryDrugDetails ();
		qac.getReferralsInDetails ();
	}
	
	public static testMethod void carePlansTest ()
	{
		Contact cl = new Contact (LastName='Test', BirthDate=Date.newInstance(1940,1,2), Gender__c='Female',Region__c='Laois',Heroin__c=true);
		insert cl;
		
		Open_Door_attendance__c od1 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,1,4), None__c=true, Days_since_last_activity__c=70);
		insert od1;
		Open_Door_attendance__c od2 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,2,4), None__c=true);
		insert od2;
		Open_Door_attendance__c od3 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,3,31), None__c=true);
		insert od3;
		Open_Door_attendance__c od4 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,4,4), None__c=true);
		insert od4;
		Open_Door_attendance__c od5 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,5,4), None__c=true);
		insert od5;
		Open_Door_attendance__c od6 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,6,4), None__c=true);
		insert od6;
		Open_Door_attendance__c od7 = new Open_Door_attendance__c (Client__c = cl.id, Date_of_attendance__c=Date.newInstance(2012,7,4), None__c=true);
		insert od7;

		Care_Plan_Objective__c cp1 = new Care_Plan_Objective__c (Client__c = cl.id, Name='Test plan 1', Date_objective_set__c=Date.newInstance(2012,4,4));
		insert cp1;
				
		Care_Plan_Objective__c cp2 = new Care_Plan_Objective__c (Client__c = cl.id, Name='Test plan 2', Date_objective_set__c=Date.newInstance(2012,5,4), Date_Completed__c=Date.newInstance (2012,6,6));
		insert cp2;

		Care_Plan_Objective__c cp3 = new Care_Plan_Objective__c (Client__c = cl.id, Name='Test plan 3', Date_objective_set__c=Date.newInstance(2012,1,4), Review_date__c=Date.newInstance (2012,2,6),Date_Completed__c=Date.newInstance (2012,3,6));
		insert cp3;

		QuarterlyActivityController qac = new QuarterlyActivityController (2012,1, 'OpenDoor');
		List<Date> months = qac.getMonths();

		system.assertEquals (1, qac.monthsData[0].Region1.CarePlansCreated);
		system.assertEquals (0, qac.monthsData[1].Region1.CarePlansCreated);
		system.assertEquals (0, qac.monthsData[2].Region1.CarePlansCreated);
		system.assertEquals (1, qac.monthsData[3].Region1.CarePlansCreated);
		system.assertEquals (1, qac.monthsData[4].Region1.CarePlansCreated);
		system.assertEquals (0, qac.monthsData[5].Region1.CarePlansCreated);
		
		system.assertEquals (1, qac.monthsData[0].Region1.CarePlansInPlace);
		system.assertEquals (1, qac.monthsData[1].Region1.CarePlansInPlace);
		system.assertEquals (1, qac.monthsData[2].Region1.CarePlansInPlace);
		system.assertEquals (1, qac.monthsData[3].Region1.CarePlansInPlace);
		system.assertEquals (1, qac.monthsData[4].Region1.CarePlansInPlace); // this is now number of individuals with care plans in place
		system.assertEquals (1, qac.monthsData[5].Region1.CarePlansInPlace);

		system.assertEquals (0, qac.monthsData[0].Region1.CarePlansReviewed);
		system.assertEquals (1, qac.monthsData[1].Region1.CarePlansReviewed);
		system.assertEquals (0, qac.monthsData[2].Region1.CarePlansReviewed);

		system.assertEquals (0, qac.monthsData[1].Region1.CarePlansCompleted);
		system.assertEquals (1, qac.monthsData[2].Region1.CarePlansCompleted);
		system.assertEquals (0, qac.monthsData[3].Region1.CarePlansCompleted);
		system.assertEquals (1, qac.monthsData[5].Region1.CarePlansCompleted);
	}
}