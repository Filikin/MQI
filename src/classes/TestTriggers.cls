@isTest
private class TestTriggers 
{ 
    static testMethod void logDateOfActivityTest() 
    {
    	Contact c = new Contact (LastName='Test');
    	insert c;
    	
    	Event e = new Event (WhoID=c.id, OwnerID=UserInfo.getUserId(), Subject='Test', StartDateTime=system.now(), EndDateTime=system.now(), None__c=true);
    	e.Event_status__c = 'Done';
    	insert e;
    	
    	c = [select id, Date_of_last_support_event__c from Contact where id=:c.id limit 1]; 
    	System.assertEquals(System.today(), c.Date_of_last_support_event__c);
    }

    static testMethod void daysGapTest() 
    {
    	Contact c = new Contact (LastName='Test');
    	insert c;
    	
    	Event e1 = new Event (WhoID=c.id, OwnerID=UserInfo.getUserId(), Subject='Test', StartDateTime=DateTime.newInstance(2012,1,5,12,30,30), EndDateTime=DateTime.newInstance(2012,1,5,13,30,30), None__c=true);
    	e1.Event_status__c = 'Done';
    	insert e1;
    	
    	Event e2 = new Event (WhoID=c.id, OwnerID=UserInfo.getUserId(), Subject='Test', StartDateTime=DateTime.newInstance(2012,1,15,12,30,30), EndDateTime=DateTime.newInstance(2012,1,15,13,30,30), None__c=true);
    	e2.Event_status__c = 'Done';
    	insert e2;

    	Event e3 = [select id, Days_since_last_activity__c from Event where id=:e2.id limit 1]; 
    	System.assertEquals(10, e3.Days_since_last_activity__c);
    }

	static testMethod void openDoorAttendanceTest ()
	{
    	Contact c = new Contact (LastName='Test');
    	insert c;
		Open_Door_attendance__c od1 = new Open_Door_attendance__c (Client__c=c.id, Date_of_attendance__c= Date.newInstance(2012,1,5), None__c = true);
		insert od1;
		Open_Door_attendance__c od2 = new Open_Door_attendance__c (Client__c=c.id, Date_of_attendance__c= Date.newInstance(2012,1,15), None__c = true);
		insert od2;
		Open_Door_attendance__c od3 = [select id, Days_since_last_activity__c from Open_Door_attendance__c where id=:od2.id];
    	System.assertEquals(10, od3.Days_since_last_activity__c);
	}

	static testMethod void harmReductionTest ()
	{
    	Contact c = new Contact (LastName='Test');
    	insert c;
		Harm_Reduction_NX__c od1 = new Harm_Reduction_NX__c (Client__c=c.id, Date_of_intervention__c= Date.newInstance(2012,1,5), None__c=true);
		insert od1;
		
		c = [select Id, Date_of_last_Harm_Reduction_NX__c from Contact where ID=:c.id];
    	System.assertEquals(od1.Date_of_intervention__c, c.Date_of_last_Harm_Reduction_NX__c);
	}
}