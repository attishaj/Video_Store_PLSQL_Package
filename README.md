
Built a PL/SQL-based application to insert and update records in a video rental store database and generate various reports. 
The database consisted of the following tables:

MEMBER(**MEMBER_ID**, NMEMBER_NAME, EMAIL, PHONE_NUMBER, REGISTRATION_DATE, EXPIRATION_DATE, LAST_UPDATE_DATE);

VIDEO(**VIDEO_ID**, VIDEO_NAME, FORMAT, PUBLISH_DATE, MAXIMUM_CHECKOUT_DAYS);

VIDEO_COPY(**VIDEO_COPY_ID**, VIDEO_ID, STATUS);

VIDEO_RENTAL_RECORD(**MEMBER_ID** * , **VIDEO_COPY_ID** * , **CHECKOUT_DATE**, DUE_DATE, RETURN_DATE);

Note:  
- * indicates foreign key relationship
- See .xlsx file for sample rows of each table 



Tasks included:

1.) Creating a procedure called member_registration to add a new member to the MEMBER table. 

    Must consider the following cases:

    a. The p_member_name is empty.
  
    b. The p_email is empty.
  
    c. The value of p_registration_date is greater than the current date. 
  
    d. The value of p_registration_date is greater than the value of p_expiration_date.

2.) Creating a procedure called update_expiration_date to update an existing member’s expiration date.  

    Must consider the following cases:

    a. The value of p_member_id is not in the MEMBER_ID column of the MEMBER table.

    b. The value of p_member_id is in the MEMBER_ID column of the MEMBER table.


3.) Creating a procedure called video_search to search a video and display the name, copy ID, format, and status of the video’s     copies. In addition, the checkout dates and due dates are also displayed for unreturned copies. The damaged copies (STATUS     = 'D') are excluded in the output. Output is sorted by video name (NAME) and then copy ID (VIDEO_COPY_ID).

4.) Creating a procedure called video_checkout to record a new rental. When the video is successfully checked out, need to     
    insert a new record into the VIDEO_RENTAL_RECORD table and update the corresponding record in the VIDEO_COPY table. Otherwise, the action is denied. 

    Must consider the following cases:
  
    a. The value of p_member_id is not in the MEMBER_ID column of the MEMBER table.
  
    b. The member’s expiration date is less than the current date. 
  
    c. The copy is not available (STATUS = 'R' or 'D').
  
    d. The value of p_video_checkout_date is greater than the current date. 
  
    e. Checkout periods are determined by the values in the MAXIMUM_CHECKOUT_DAYS column. The due date is p_video_checkout_date plus the corresponding MAXIMUM_CHECKOUT_DAYS.
  
    f. A member may have up to seven (7) copies checked out at any one time. 
  
    g. Before a member returns a copy, he/she cannot rent a second copy of the same video (VIDEO_ID). 	

5.) Creating a procedure called video_return to change the rental status for that returned copy. When the copy is successfully     checked in, need to update the corresponding records in the VIDEO_RENTAL_RECORD and VIDEO_COPY tables. Otherwise, the          action is denied. 

    Must consider the following cases:

    a. The value of p_video_copy_id does not exist in the corresponding column of the VIDEO_COPY table.

    b. The status of that copy is not 'R'.

    c. The value of p_video_return_date is greater than the current date. 


6.) Creating a procedure called print_unreturned_video to retrieve all the copies that a member hasn't returned. The output 
    includes the member's ID, name, expiration date, first checkout date, last checkout date, the number of unreturned copies, video name, copy ID, format, checkout date, and due date of the rentals. Output is sorted by due date and then video name.

7.) Grouping all the above subprograms (member_registration, update_expiration_date, video_search, video_checkout, 
    video_return, and print_unreturned_video) together in a package (package specification and package body) called video_pkg. 

