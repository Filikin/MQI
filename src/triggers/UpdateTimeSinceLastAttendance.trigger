trigger UpdateTimeSinceLastAttendance on Open_Door_attendance__c (before insert) 
{ 
    Set<Id> setContacts = new Set<ID>();

 	for(Open_Door_attendance__c od : Trigger.new)
    {
        setContacts.add(od.Client__c);
    }
    
    Map<ID, Contact> mapClients = new Map<ID, Contact>([select Id, Date_of_last_open_door_attendance__c from Contact where ID in :setContacts]);
  	for(Open_Door_attendance__c od : Trigger.new)
    {
    	Contact client = mapClients.get(od.Client__c);
    	if (Trigger.isInsert && client.Date_of_last_open_door_attendance__c != null) 
    		od.Days_since_last_activity__c = client.Date_of_last_open_door_attendance__c.daysBetween(od.Date_of_attendance__c); 
    }

}