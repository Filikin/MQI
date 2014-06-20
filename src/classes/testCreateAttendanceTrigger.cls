@isTest
private class testCreateAttendanceTrigger 
{
    static testMethod void createAttendanceTest() 
    {
    	Contact youngPerson = new Contact (LastName = 'Kelly');
    	insert youngPerson;
    	
    	Program_Service__c program = new Program_Service__c (Name = 'Music');
    	insert program;
    	
    	Enrolment__c enrole = new Enrolment__c (Program_Service__c=program.id, Young_Person__c=youngPerson.id);
    	insert enrole;
    	
    	Integer preAttendances = [select count() from Attendance__c];
    	
    	Program_Session__c session = new Program_Session__c (Program_Service__c=program.id);
    	insert session;
    	
    	Integer postAttendances = [select count() from Attendance__c];
    	
    	System.Assert (postAttendances == preAttendances + 1);
    	
    	ProgramAttendanceListView rsa = new ProgramAttendanceListView(session);
    	rsa.submit();
    	rsa.getAttendanceList(); 
    }
    
    static testMethod void testCreateCarePlanStepAttendanceTrigger()
    {
    	Contact youngPerson = new Contact (LastName = 'Kelly');
    	insert youngPerson;
    	
    	Program_Service__c program = new Program_Service__c (Name = 'Music');
    	insert program;
    	
    	Care_Plan_Objective__c careplan = new Care_Plan_Objective__c (Name='Improve welbeing', Client__c=youngPerson.id);
    	insert careplan;
    	
    	Enrolment__c enrole = new Enrolment__c (Program_Service__c=program.id, Young_Person__c=youngPerson.id, Care_Plan_Objective__c=careplan.id);
    	insert enrole;
    	
    	Integer preCarePlanSteps = [select count() from Care_plan_step__c where Reference__c != null];
    	
    	Program_Session__c session = new Program_Session__c (Program_Service__c=program.id, Session_Date__c=system.today()-1);
    	insert session;
    	
    	Integer postCarePlanSteps = [select count() from Care_plan_step__c where Reference__c != null];
 
     	System.Assert (postCarePlanSteps == preCarePlanSteps + 1);
     	
     	Attendance__c attend = [select ID, Attended__c from Attendance__c where Enrolment__r.Care_Plan_Objective__c = :careplan.id];
     	attend.Attended__c = True;
     	update attend;
     	
     	Care_plan_step__c careplanstep = [select ID, Reference__c, Description__c from Care_plan_step__c where Care_Plan_Objective__c = :careplan.id];
     	System.debug(careplanstep.Description__c);
     	System.assert(careplanstep.Description__c.contains ('Attended'));

     	attend.Attended__c = False;
     	update attend;
     	
     	Care_plan_step__c careplanstep2 = [select ID, Reference__c, Description__c from Care_plan_step__c where Care_Plan_Objective__c = :careplan.id];
     	System.debug(careplanstep2.Description__c);
     	System.assert(careplanstep2.Description__c.contains ('Did not attend'));

    }
}