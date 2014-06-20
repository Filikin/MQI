@isTest
private class testCarePlanEventTrigger 
{
   	static testMethod void testCreateCarePlanStepEventTrigger()
    {
    	Contact youngPerson = new Contact (LastName = 'Kelly');
    	insert youngPerson;
    	
    	Care_Plan_Objective__c careplan = new Care_Plan_Objective__c (Name='Improve welbeing', Client__c=youngPerson.id);
    	insert careplan;
    	
    	
    	Integer preCarePlanSteps = [select count() from Care_plan_step__c where Reference__c != null];
    	
	   	Event e1 = new Event (WhoID=youngPerson.id, OwnerID=UserInfo.getUserId(), WhatID=careplan.id, Subject='Test', StartDateTime=DateTime.newInstance(2012,1,5,12,30,30), EndDateTime=DateTime.newInstance(2012,1,5,13,30,30), None__c=true);
    	insert e1;
     	
    	Integer postCarePlanSteps = [select count() from Care_plan_step__c where Reference__c != null];
 
     	System.Assert (postCarePlanSteps == preCarePlanSteps + 1);
     	
     	e1.Subject='Finished';
     	update e1;
     	
     	Care_plan_step__c careplanstep = [select ID, Reference__c, Description__c from Care_plan_step__c where Care_Plan_Objective__c = :careplan.id];
     	System.debug(careplanstep.Description__c);
     	System.assert(careplanstep.Description__c.contains ('Finished'));
    }
}