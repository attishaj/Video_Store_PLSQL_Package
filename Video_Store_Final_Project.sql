--John Attisha
--CSC 452
--Final Project

CREATE OR REPLACE PACKAGE video_pkg IS
  PROCEDURE member_registration    (p_member_id           NUMBER, 
                                    p_member_name         VARCHAR2, 
                                    p_email               VARCHAR2, 
                                    p_phone_number        VARCHAR2, 
                                    p_registration_date	  DATE,	
                                    p_expiration_date     DATE);
  
  PROCEDURE update_expiration_date (p_member_id           NUMBER,
                                    p_new_expiration_date DATE);
                                    
  PROCEDURE video_search           (p_video_name          VARCHAR2,
                                    p_format              VARCHAR2 DEFAULT NULL);
                                    
  PROCEDURE video_checkout         (p_member_id           NUMBER,
                                    p_video_copy_id       NUMBER,
                                    p_video_checkout_date DATE);
                                    
  PROCEDURE video_return           (p_video_copy_id       NUMBER,
                                    p_video_return_date   DATE);
                                    
  PROCEDURE print_unreturned_video (p_member_id           NUMBER);

END video_pkg;
/

CREATE OR REPLACE PACKAGE BODY video_pkg IS
 PROCEDURE member_registration
  (	
   p_member_id          NUMBER,
   p_member_name        VARCHAR2,
   p_email              VARCHAR2, 
   p_phone_number       VARCHAR2,
   p_registration_date  DATE,
   p_expiration_date    DATE) 
 IS
   v_count              NUMBER;
   v_status             CHAR;
 BEGIN
   IF p_member_id <= 0 THEN
    DBMS_OUTPUT.PUT_LINE('Invalid member ID!');
    RETURN;
   END IF;

   SELECT COUNT(*)
   INTO	  v_count
   FROM	  member
   WHERE  member_id = p_member_id;

   IF v_count != 0 THEN
    DBMS_OUTPUT.PUT_LINE('Invalid member ID!');
    RETURN;
   END IF;

   IF p_member_name is NULL THEN 
    DBMS_OUTPUT.PUT_LINE('Invalid member name!');
    RETURN;
   END IF;

   IF p_email is NULL THEN 
    DBMS_OUTPUT.PUT_LINE('Invalid email address!');
    RETURN;
   END IF;

   IF p_registration_date IS NULL OR 
    TO_CHAR(p_registration_date, 'yyyymmdd') > TO_CHAR(sysdate, 'yyyymmdd') THEN
     DBMS_OUTPUT.PUT_LINE('Invalid registration date!');
     RETURN;
   END IF;

   IF p_expiration_date IS NULL OR
    TO_CHAR(p_expiration_date, 'yyyymmdd') < 
    TO_CHAR(p_registration_date, 'yyyymmdd') THEN
     DBMS_OUTPUT.PUT_LINE('Invalid expiration date!');
     RETURN;
   END IF;
  
   INSERT INTO member 
      VALUES(p_member_id, UPPER(p_member_name), p_email, p_phone_number,
             p_registration_date, p_expiration_date, sysdate);
   COMMIT;
	
   DBMS_OUTPUT.PUT_LINE (INITCAP(p_member_name) || ' has been added into the member table.');
 		
 EXCEPTION
   WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('My exception: ' || TO_CHAR(SQLCODE) || '   ' || SQLERRM);
 END member_registration;
 
 --begin second procedure
 PROCEDURE update_expiration_date 
  (
   p_member_id 	        	NUMBER,
   p_new_expiration_date 	DATE)
 IS
   v_mbr_id_count               NUMBER;
   v_registration_date          DATE;
 BEGIN
   IF p_member_id <= 0 THEN  
     DBMS_OUTPUT.PUT_LINE('Invalid Member ID!');
     RETURN;
   END IF;
  
   SELECT COUNT(*)
   INTO   v_mbr_id_count
   FROM   member
   WHERE  member_id = p_member_id;
  
   IF v_mbr_id_count = 0 THEN --this member doesn't exist in the 'member' table
     DBMS_OUTPUT.PUT_LINE('Invalid Member ID!');
     RETURN;
   END IF;
  
   SELECT registration_date
   INTO   v_registration_date
   FROM   member
   WHERE  member_id = p_member_id;
  
   IF TO_CHAR(p_new_expiration_date, 'yyyymmdd') < TO_CHAR(v_registration_date, 'yyyymmdd') THEN --new expiration date can't be before registration date
     DBMS_OUTPUT.PUT_LINE('Invalid expiration date!');
     RETURN;
   END IF;
  
   UPDATE member  --if the member is in the 'member' table and the new expiration date is acceptable, then update two columns
   SET    expiration_date = p_new_expiration_date,
          last_update_date = sysdate
   WHERE  member_id = p_member_id;
   COMMIT;

   DBMS_OUTPUT.PUT_LINE('The expiration date has been updated.');

 EXCEPTION
   WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('My exception: ' || TO_CHAR(SQLCODE) || '   ' || SQLERRM);
 END update_expiration_date;
 
  --begin third procedure
 PROCEDURE video_search 
  (
   p_video_name       VARCHAR2, 
   p_format           VARCHAR2 DEFAULT NULL)
 IS
   v_vid_count      NUMBER;
   v_avail_count    NUMBER;
   v_video_id       video.video_id%TYPE;
   v_video_name     video.video_name%TYPE;
   v_format         video.format%TYPE;
   v_video_copy_id  video_copy.video_copy_id%TYPE;
   v_status         video_copy.status%TYPE;
   v_status_full    VARCHAR2(10);
   v_max_ckout_dt   DATE;
   v_due_dt         DATE;
   v_output         VARCHAR2(500) := ''; 
  
   CURSOR c_1(p_vname VARCHAR2, p_fmt VARCHAR2) IS
     SELECT     v.video_id, video_name, format, video_copy_id, status
     FROM       video v
     INNER JOIN video_copy vc
     ON         v.video_id = vc.video_id
     WHERE      UPPER(video_name) like '%' || UPPER(p_vname) || '%' 
     AND        UPPER(format) = DECODE(p_fmt, NULL, UPPER(format), UPPER(p_fmt))
     AND        status != 'D'
     ORDER BY   video_name, video_copy_id;
    
 BEGIN
   SELECT      COUNT(*) 
   INTO        v_vid_count
   FROM        video
   INNER JOIN  video_copy
   ON          video.video_id = video_copy.video_id
   WHERE       UPPER(video_name) like '%' || UPPER(p_video_name) || '%' 
   AND         UPPER(format) = DECODE(p_format, NULL, UPPER(format), UPPER(p_format))
   AND         status != 'D';
   
   IF v_vid_count = 0 THEN --video isn't in the 'video' table
     IF p_format IS NULL THEN
       DBMS_OUTPUT.PUT_LINE('***** ' || TO_CHAR(v_vid_count) || ' results found for ' || p_video_name || '. *****');
     ELSE
       DBMS_OUTPUT.PUT_LINE('***** ' || TO_CHAR(v_vid_count) || ' results found for ' || p_video_name || ' (' || p_format || '). *****');
     RETURN;
     END IF;
   ELSE  --there are videos in the 'video' table
     SELECT       COUNT(*) --this tells us how many copies there are available
     INTO         v_avail_count
     FROM         video_copy
     INNER JOIN   video
     ON           video_copy.video_id = video.video_id
     WHERE        UPPER(video_name) like '%' || UPPER(p_video_name) || '%' 
     AND          UPPER(format) = DECODE(p_format, NULL, UPPER(format), UPPER(p_format))
     AND          status = 'A';
    
     IF p_format IS NULL THEN
       DBMS_OUTPUT.PUT_LINE('***** ' || TO_CHAR(v_vid_count) || ' results found for ' || p_video_name || '. (Available copies: ' || TO_CHAR(v_avail_count) || ') *****');
     ELSE
       DBMS_OUTPUT.PUT_LINE('***** ' || TO_CHAR(v_vid_count) || ' results found for ' || p_video_name || ' (' || p_format || ')' || '. (Available copies: ' || TO_CHAR(v_avail_count) || ') *****');
     END IF;
    
     DBMS_OUTPUT.PUT_LINE ('');
     DBMS_OUTPUT.PUT_LINE ('VIDEO NAME           VIDEO COPY ID    FORMAT      STATUS         CHECKOUT DATE       DUE DATE');
     DBMS_OUTPUT.PUT_LINE ('---------------------------------------------------------------------------------------------');
    
     OPEN c_1(p_video_name, p_format);
     FETCH c_1 INTO v_video_id, v_video_name, v_format, v_video_copy_id, v_status;
     WHILE c_1%FOUND LOOP
       IF v_status = 'A' THEN 
         v_status_full := 'Available';
       ELSE
         v_status_full := 'Rented';
         SELECT MAX(checkout_date)
         INTO   v_max_ckout_dt
         FROM   video_rental_record
         WHERE  video_copy_id = v_video_copy_id;
        
         SELECT due_date
         INTO   v_due_dt
         FROM   video_rental_record
         WHERE  video_copy_id = v_video_copy_id AND checkout_date = v_max_ckout_dt;
       
       END IF;
      
       v_output := RPAD(v_video_name, 21, ' ') || LPAD(v_video_copy_id, 13, ' ') || '    ' || RPAD(v_format, 12, ' ') || RPAD(v_status_full, 15, ' ');
       IF v_status = 'A' THEN
         DBMS_OUTPUT.PUT_LINE(v_output);
       ELSE
         v_output := v_output || LPAD(TO_CHAR(v_max_ckout_dt,'DD-MON-YYYY'), 13, ' ') || LPAD(TO_CHAR(v_due_dt,'DD-MON-YYYY'), 15, ' ');
         DBMS_OUTPUT.PUT_LINE(v_output);
       END IF;
       FETCH c_1 INTO v_video_id, v_video_name, v_format, v_video_copy_id, v_status;
       v_output := '';
     END LOOP;
     CLOSE c_1;
   END IF;
   
 EXCEPTION
   WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('My exception: ' || TO_CHAR(SQLCODE) || '   ' || SQLERRM);
 END video_search;

 --begin fourth procedure
 PROCEDURE video_checkout
  (
   p_member_id            NUMBER, 
   p_video_copy_id        NUMBER, 
   p_video_checkout_date  DATE )
 IS
   v_mbr_count            NUMBER;
   v_mbr_exp_date         DATE;
   v_cpy_count            NUMBER;
   v_cpy_status           CHAR;
   v_ckout_count          NUMBER;
   v_video_id             NUMBER;
   v_count_vid_id         NUMBER;
   v_max_ckout_days       NUMBER;
   v_due_date             DATE;
  
 BEGIN
   SELECT COUNT(*)
   INTO   v_mbr_count
   FROM   member
   WHERE  member_id = p_member_id;
  
   IF v_mbr_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Invalid Member ID!');
    RETURN;
   END IF;

   SELECT expiration_date
   INTO   v_mbr_exp_date
   FROM   member
   WHERE  member_id = p_member_id;
  
   IF v_mbr_exp_date < sysdate THEN
    DBMS_OUTPUT.PUT_LINE('Registration Expired!'); 
    RETURN;
   END IF;

   SELECT COUNT(*)
   INTO   v_cpy_count
   FROM   video_copy
   WHERE  video_copy_id = p_video_copy_id;
  
   IF v_cpy_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Invalid Video Copy ID!');
    RETURN;
   END IF;
  
   SELECT status
   INTO   v_cpy_status
   FROM   video_copy
   WHERE  video_copy_id = p_video_copy_id;
  
   IF v_cpy_status != 'A' THEN
     DBMS_OUTPUT.PUT_LINE('Video Copy ID Not Available!');
     RETURN;
   END IF;
  
   IF p_video_checkout_date > sysdate THEN
     DBMS_OUTPUT.PUT_LINE('Checkout date cannot be in the future!');
     RETURN;
   END IF;
  
   SELECT COUNT(*)  --check if member has >7 copies checked out
   INTO   v_ckout_count
   FROM   video_rental_record
   WHERE  member_id = p_member_id AND return_date IS NULL; 
  
   IF v_ckout_count >= 7 THEN  
    DBMS_OUTPUT.PUT_LINE('Member cannot check out more than 7 videos at one time!'); 
    RETURN;
   END IF;
  
   SELECT video_id  --check if member currently has a video with the same video_id already checked out
   INTO   v_video_id
   FROM   video_copy
   WHERE  video_copy_id = p_video_copy_id ; 
  
   SELECT     COUNT(*)
   INTO       v_count_vid_id
   FROM       video_copy vc
   INNER JOIN video_rental_record vrr
   ON         vc.video_copy_id = vrr.video_copy_id
   WHERE      member_id = p_member_id
   AND        return_date IS NULL
   AND        video_id = v_video_id;
  
   IF v_count_vid_id > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Member cannot have two videos with the same Video ID checked out at the same time!');
    RETURN;
   END IF;
  
  --everything is good to go now. the video can be checked out.

   UPDATE video_copy  --update status of the video_copy_id
   SET    status = 'R'
   WHERE  video_copy_id = p_video_copy_id;
   COMMIT;
  
   SELECT maximum_checkout_days 
   INTO   v_max_ckout_days
   FROM   video
   WHERE  video_id = v_video_id;
  
   v_due_date := p_video_checkout_date + v_max_ckout_days;  
  
   INSERT INTO video_rental_record 
     VALUES (p_member_id, p_video_copy_id, p_video_checkout_date, v_due_date, NULL);
   COMMIT;
  
   DBMS_OUTPUT.PUT_LINE('Video has been successfully checked out!');
 
 EXCEPTION
   WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('My exception: ' || TO_CHAR(SQLCODE) || ' ' || SQLERRM);
 END video_checkout;


  --begin fifth procedure
 PROCEDURE video_return
  (
   p_video_copy_id        NUMBER, 
   p_video_return_date 	  DATE)
 IS
   v_vid_count  NUMBER;
   v_vid_status CHAR;
   v_member_id  NUMBER;
   v_chkout_dt  DATE;

 BEGIN
  SELECT COUNT(*)
  INTO   v_vid_count
  FROM   video_copy
  WHERE  video_copy_id = p_video_copy_id;
 
  IF v_vid_count = 0 THEN
   DBMS_OUTPUT.PUT_LINE('Invalid Video ID!');
   RETURN;
  END IF;

  SELECT status
  INTO   v_vid_status
  FROM   video_copy
  WHERE  video_copy_id = p_video_copy_id;
 
  IF v_vid_status != 'R' THEN
   DBMS_OUTPUT.PUT_LINE('Video not checked out!');
   RETURN;
  END IF;
 
  IF p_video_return_date > sysdate THEN
   DBMS_OUTPUT.PUT_LINE('Return date cannot be in the future!');
   RETURN;
  END IF;
 
  --if everything is okay, then we can proceed with checking in the video
 
  UPDATE video_copy
  SET    status = 'A'
  WHERE  video_copy_id = p_video_copy_id;
  COMMIT;
 
  SELECT member_id, checkout_date
  INTO   v_member_id, v_chkout_dt
  FROM   video_rental_record
  WHERE  video_copy_id = p_video_copy_id
  AND    return_date IS NULL;
 
 
  UPDATE video_rental_record
  SET    return_date = p_video_return_date
  WHERE  member_id = v_member_id
  AND    video_copy_id = p_video_copy_id
  AND    checkout_date = v_chkout_dt;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Video has been successfully checked in!'); 
 
 EXCEPTION
  WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('My exception: ' || TO_CHAR(SQLCODE) || ' ' || SQLERRM); 
 END video_return;

  --begin sixth procedure
 PROCEDURE print_unreturned_video
  (p_member_id   NUMBER)
 IS
   v_mbr_count   NUMBER;
   v_rent_count  NUMBER;
   v_mbr_name    member.member_name%TYPE;
   v_exp_date    VARCHAR2(15);
   v_first_vid_c VARCHAR2(15);
   v_last_vid_c  VARCHAR2(15);
   v_first_vid   DATE;
   v_last_vid    DATE;
   v_unret_count NUMBER;

   CURSOR c_unret_vid IS
     SELECT     vrr.video_copy_id, checkout_date, due_date, format, video_name
     FROM       video_rental_record vrr
     INNER JOIN video_copy vc 
     ON         vrr.video_copy_id = vc.video_copy_id
     INNER JOIN video v
     ON         vc.video_id = v.video_id
     WHERE      vrr.member_id = p_member_id
     AND        vrr.return_date IS NULL
     ORDER BY   vrr.due_date, v.video_name;
 
 BEGIN
   SELECT COUNT(*)
   INTO   v_mbr_count
   FROM   member
   WHERE  member_id = p_member_id;
   
   IF v_mbr_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('The member (id = ' || TO_CHAR(p_member_id) || ') is not in the member table.');
    RETURN;
   END IF;
   
   SELECT member_name
   INTO   v_mbr_name
   FROM   member
   WHERE  member_id = p_member_id;
   
   SELECT TO_CHAR(expiration_date, 'DD-MON-YYYY')
   INTO   v_exp_date
   FROM   member
   WHERE  member_id = p_member_id;
    
   SELECT COUNT(*)
   INTO   v_rent_count
   FROM   video_rental_record
   WHERE  member_id = p_member_id;
   
   IF v_rent_count = 0 THEN --member hasn't checked anything out
      v_first_vid_c := 'N/A';
      v_last_vid_c  := 'N/A';
      v_unret_count := 0;  --if member hasn't checked anything out then they have 0 unreturned videos
  
   ELSE  --the member has checked out one or more videos
     SELECT MIN(checkout_date), MAX(checkout_date) --get the first and last dates
     INTO   v_first_vid, v_last_vid
     FROM   video_rental_record
     WHERE  member_id = p_member_id;
    
     SELECT COUNT(*)  --this tells us how many unreturned videos the member has
     INTO   v_unret_count
     FROM   video_rental_record
     WHERE  member_id = p_member_id
     AND    return_date IS NULL;
   END IF;
    
   DBMS_OUTPUT.PUT_LINE('----------------------------------------');
   DBMS_OUTPUT.PUT_LINE(RPAD('Member ID:', 25, ' ') || TO_CHAR(p_member_id));
   DBMS_OUTPUT.PUT_LINE(RPAD('Member Name:', 25, ' ') || v_mbr_name);
   DBMS_OUTPUT.PUT_LINE(RPAD('Expiration Date:', 25, ' ') || v_exp_date);
   IF v_rent_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE(RPAD('First Checkout Date:', 25, ' ') || v_first_vid_c); 
    DBMS_OUTPUT.PUT_LINE(RPAD('Last Checkout Date:',  25, ' ') || v_last_vid_c);
   ELSE
    DBMS_OUTPUT.PUT_LINE(RPAD('First Checkout Date:', 25, ' ') || TO_CHAR(v_first_vid, 'DD-MON-YYYY')); 
    DBMS_OUTPUT.PUT_LINE(RPAD('Last Checkout Date:',  25, ' ') || TO_CHAR(v_last_vid, 'DD-MON-YYYY'));
   END IF;
   DBMS_OUTPUT.PUT_LINE('----------------------------------------');
   DBMS_OUTPUT.PUT_LINE('Number of Unreturned Videos:' || LPAD(TO_CHAR(v_unret_count), 3, ' '));
   DBMS_OUTPUT.PUT_LINE('----------------------------------------');

   IF v_unret_count !=0 THEN
    FOR idx in c_unret_vid LOOP
      DBMS_OUTPUT.PUT_LINE(RPAD('Video Copy ID:',17,' ') || TO_CHAR(idx.video_copy_id));
      DBMS_OUTPUT.PUT_LINE(RPAD('Video Name:',17,' ') || idx.video_name);
      DBMS_OUTPUT.PUT_LINE(RPAD('Format:',17,' ') || idx.format);
      DBMS_OUTPUT.PUT_LINE(RPAD('Checkout Date:',17,' ') || TO_CHAR(idx.checkout_date,'DD-MON-YYYY'));
      DBMS_OUTPUT.PUT_LINE(RPAD('Due Date:',17,' ') || TO_CHAR(idx.due_date,'DD-MON-YYYY'));
      DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
   END IF;
   RETURN;  

 EXCEPTION
   WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('My exception: ' || TO_CHAR(SQLCODE) || ' ' || SQLERRM);
 END print_unreturned_video;

END video_pkg;
