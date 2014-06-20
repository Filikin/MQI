public with sharing class ViewCarePlan 
{
	public List<Care_Plan_Objective__c> carePlanObjectives = new List<Care_Plan_Objective__c>();
	public List<Care_plan_step__c> carePlanSteps = new List<Care_plan_step__c>();
    public ID recordID;
    public String recordName;
    public String counsellor {get;set;}
	
    public ViewCarePlan (ApexPages.StandardController controller) 
    {
        sObject con = controller.getRecord();
        recordID = con.id;
	    Contact client = [select Name, Counsellor__r.Name from Contact where id = :con.id];
	    if (client != null)
	    {
	    	recordName = client.Name;
	    	counsellor = client.Counsellor__r.Name;
	    }
        
        carePlanObjectives = [SELECT ID, Name, Comment_Reasons_achieved_or_not__c, Date_completed__c, Date_objective_set__c, How_will_progress_be_measured__c,
        	Lead_Agency_name__c, Lead_Key_Worker_name__c, Next_Review_Date__c, Objective_and_Timescale__c, Objective_Status__c, Outcome__c, Referred_to__c, Time_Frame_short__c,
        	  Work_to_be_done_to_achieve_objective__c, Care_plan_step_count__c FROM Care_Plan_Objective__c where Client__c = :recordID order by CreatedDate DESC, Date_objective_set__c DESC];
        
        
        if (carePlanObjectives.size() > 0)
        {
	        Set<ID>carePlanObjectiveIDs = new Set<ID>();
	        for (Care_Plan_Objective__c oneCarePlanObjective: carePlanObjectives)
	        	carePlanObjectiveIDs.add(oneCarePlanObjective.ID);
	        	
	        carePlanSteps = [SELECT ID, Name, Date__c, Description__c, Care_Plan_Objective__c FROM Care_plan_step__c where Care_Plan_Objective__c in :carePlanObjectiveIDs order by Date__c DESC, Description__c];
        }
    }
    
    public List<Care_Plan_Objective__c> getCarePlanObjectives() 
    {
        return carePlanObjectives;
    }
    
    public List<Care_plan_step__c> getCarePlanSteps() 
    {
        return carePlanSteps;
    }

    public static testMethod ViewCarePlan testViewCarePlan()
    {
    	Contact youngPerson = new Contact (LastName = 'Kelly');
    	insert youngPerson;
    	
    	Care_Plan_Objective__c careplan = new Care_Plan_Objective__c (Name='Improve welbeing', Client__c=youngPerson.id);
    	insert careplan;
    	
	   	Event e1 = new Event (WhoID=youngPerson.id, OwnerID=UserInfo.getUserId(), WhatID=careplan.id, Subject='Test', StartDateTime=DateTime.newInstance(2012,1,5,12,30,30), EndDateTime=DateTime.newInstance(2012,1,5,13,30,30), None__c=true);
    	insert e1;
    	
        ApexPages.StandardController contactController = new ApexPages.StandardController(youngPerson);
        return new ViewCarePlan (contactController);
    }
    
    public static testMethod void testRemainingBits ()
    {
    	ViewCarePlan thisClass = testViewCarePlan();
    	thisClass.getCarePlanObjectives();
    	thisClass.getCarePlanSteps();
    }

}