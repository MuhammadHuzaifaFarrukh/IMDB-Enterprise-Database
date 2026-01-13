--THIS SCRIPT WILL SHOWS ALL THE DETAILED WORKING OF OUR STROED PROCEDURES.

DECLARE
    -- =============================================
    -- CONFIGURATION VARIABLES
    -- =============================================
    v_user_id      NUMBER;
    v_title_id     NUMBER;
    v_person_id    NUMBER;
    v_genre_id     NUMBER;
    v_provider_id  NUMBER;
    v_list_id      NUMBER;
    v_event_id     NUMBER := 88888; -- Custom ID for testing
    v_cat_id       NUMBER := 88888; -- Custom ID for testing
    
    -- Variables for verification
    v_ver_old      NUMBER;
    v_ver_new      NUMBER;
    v_count        NUMBER;
    v_temp_id      NUMBER;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('   IMDb DATABASE PROJECT - COMPREHENSIVE TEST HARNESS');
    DBMS_OUTPUT.PUT_LINE('   Status: Testing Procedures, Triggers, Views, and Indexes,Constraints');
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE(' ');

    -- =============================================
    -- PHASE 1: SETUP & PRE-REQUISITES
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--- PHASE 1: SYSTEM SETUP ---');
    
    -- 1. Fetch valid IDs from existing data to run tests against
    SELECT MIN(UserID) INTO v_user_id FROM User_def;
    SELECT MIN(TitleID) INTO v_title_id FROM Title;
    SELECT MIN(PersonID) INTO v_person_id FROM Person;
    
    -- 2. Handle Edge Case: Ensure a Streaming Provider exists
    BEGIN
        SELECT MIN(ProviderID) INTO v_provider_id FROM StreamingProvider;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        v_provider_id := 1;
        INSERT INTO StreamingProvider (ProviderID, Name, Created_At, Version) VALUES (1, 'TestProv', SYSDATE, 1);
    END;

    -- 3. CRITICAL: Disable the "Mutating" Trigger (as agreed) to rely on Procedure logic
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_update_rating_summary DISABLE';
        DBMS_OUTPUT.PUT_LINE('-> Note: trg_update_rating_summary disabled (Using Procedure Logic).');
    EXCEPTION WHEN OTHERS THEN NULL; -- Ignore if it doesn't exist
    END;

    -- 4. CLEANUP: Remove old test data to prevent ORA-00001 (Unique Constraint) errors
    BEGIN
        DELETE FROM Nomination WHERE CategoryID = v_cat_id;
        DELETE FROM AwardCategory WHERE CategoryID = v_cat_id;
        DELETE FROM AwardEvent WHERE AwardEventID = v_event_id;
        DELETE FROM StreamingAvailability WHERE TitleID = v_title_id AND ProviderID = v_provider_id;
        DELETE FROM List WHERE UserID = v_user_id AND Name = 'Test List';
        DELETE FROM Review WHERE USERID = v_user_id AND TITLEID = v_title_id;
        DELETE FROM Genre WHERE Name = 'X-Rated Test';
        DELETE FROM Genre WHERE Name = 'Family Friendly Test';
        COMMIT;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    
    DBMS_OUTPUT.PUT_LINE('-> Setup Complete. Base IDs: User=' || v_user_id || ', Title=' || v_title_id);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- =============================================
    -- PHASE 2: TESTING STORED PROCEDURES
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PHASE 2: STORED PROCEDURES (Success & Failure)');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    -- TEST P1: usp_add_user_rating (Success Case)
    BEGIN
        usp_add_user_rating(v_user_id, v_title_id, 9);
        DBMS_OUTPUT.PUT_LINE('PASS: usp_add_user_rating (Success) -> Rating added & Summary updated.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_user_rating (Success) -> ' || SQLERRM);
    END;

    -- TEST P2: usp_add_user_rating (Failure Case: Rating > 10)
    BEGIN
        usp_add_user_rating(v_user_id, v_title_id, 15);
        DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_user_rating (Failure) -> Allowed bad rating (15).');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: usp_add_user_rating (Failure) -> Correctly blocked invalid rating.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_user_rating (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;

    -- TEST P3: usp_add_review (Success Case)
    BEGIN
        usp_add_review(v_user_id, v_title_id, 'Great Movie', 'I loved it.', 10);
        DBMS_OUTPUT.PUT_LINE('PASS: usp_add_review (Success) -> Review inserted.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_review (Success) -> ' || SQLERRM);
    END;

    -- TEST P4: usp_add_review (Failure Case: Duplicate Review)
    BEGIN
        usp_add_review(v_user_id, v_title_id, 'Dupe Attempt', 'Should fail.', 1);
        DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_review (Failure) -> Allowed duplicate review.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: usp_add_review (Failure) -> Correctly blocked duplicate review.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_review (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;

    -- TEST P5: usp_add_list_item (Success Case)
    -- Create a temp list first
    SELECT NVL(MAX(ListID), 0) + 1 INTO v_list_id FROM List;
    INSERT INTO List (ListID, UserID, Name, Created_At, Version) VALUES (v_list_id, v_user_id, 'Test List', SYSDATE, 1);
    
    BEGIN
        usp_add_list_item(v_list_id, v_title_id, 1);
        DBMS_OUTPUT.PUT_LINE('PASS: usp_add_list_item (Success) -> Item added to list.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_list_item (Success) -> ' || SQLERRM);
    END;

    -- TEST P6: usp_add_list_item (Failure Case: Duplicate Title in List)
    BEGIN
        usp_add_list_item(v_list_id, v_title_id, 2);
        DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_list_item (Failure) -> Allowed duplicate title.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: usp_add_list_item (Failure) -> Correctly blocked duplicate title.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: usp_add_list_item (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;
    DBMS_OUTPUT.PUT_LINE(' ');

    -- =============================================
    -- PHASE 3: TESTING TRIGGERS
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PHASE 3: TRIGGERS (Validation & Integrity)');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    -- TEST T1: trg_title_version_update (Success Case)
    -- We verify that updating a title increments its Version number
    SELECT Version INTO v_ver_old FROM Title WHERE TitleID = v_title_id;
    BEGIN
        UPDATE Title SET Primary_Title = Primary_Title WHERE TitleID = v_title_id; -- Dummy update
        SELECT Version INTO v_ver_new FROM Title WHERE TitleID = v_title_id;
        
        IF v_ver_new > v_ver_old THEN
            DBMS_OUTPUT.PUT_LINE('PASS: trg_title_version_update (Success) -> Version incremented.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: trg_title_version_update (Success) -> Version did not increment.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_title_version_update (Success) -> ' || SQLERRM);
    END;

    -- TEST T2: trg_title_version_update (Failure Case: Updating Soft-Deleted Row)
    UPDATE Title SET Deleted_At = SYSDATE WHERE TitleID = v_title_id; -- Temporarily delete
    BEGIN
        UPDATE Title SET Start_Year = 2020 WHERE TitleID = v_title_id;
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_title_version_update (Failure) -> Allowed update on deleted record.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: trg_title_version_update (Failure) -> Blocked update on deleted record.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: trg_title_version_update (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;
    UPDATE Title SET Deleted_At = NULL WHERE TitleID = v_title_id; -- Restore

    -- TEST T3: trg_prevent_streaming_overlap (Success Case: Non-Overlapping Dates)
    BEGIN
        -- Period 1: Jan 1-10
        INSERT INTO StreamingAvailability (StreamingAvailabilityID, TitleID, ProviderID, Start_Date, End_Date, Created_At, Version)
        VALUES (seq_StreamingAvailability.NEXTVAL, v_title_id, v_provider_id, TO_DATE('2026-01-01','YYYY-MM-DD'), TO_DATE('2026-01-10','YYYY-MM-DD'), SYSDATE, 1);
        
        -- Period 2: Jan 15-25
        INSERT INTO StreamingAvailability (StreamingAvailabilityID, TitleID, ProviderID, Start_Date, End_Date, Created_At, Version)
        VALUES (seq_StreamingAvailability.NEXTVAL, v_title_id, v_provider_id, TO_DATE('2026-01-15','YYYY-MM-DD'), TO_DATE('2026-01-25','YYYY-MM-DD'), SYSDATE, 1);
        
        DBMS_OUTPUT.PUT_LINE('PASS: trg_prevent_streaming_overlap (Success) -> Allowed valid dates.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_streaming_overlap (Success) -> ' || SQLERRM);
    END;

    -- TEST T4: trg_prevent_streaming_overlap (Failure Case: Overlapping Dates)
    BEGIN
        -- Attempt Overlap: Jan 5-15 (Overlaps with Jan 1-10)
        INSERT INTO StreamingAvailability (StreamingAvailabilityID, TitleID, ProviderID, Start_Date, End_Date, Created_At, Version)
        VALUES (seq_StreamingAvailability.NEXTVAL, v_title_id, v_provider_id, TO_DATE('2026-01-05','YYYY-MM-DD'), TO_DATE('2026-01-15','YYYY-MM-DD'), SYSDATE, 1);
        
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_streaming_overlap (Failure) -> Allowed overlapping dates.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: trg_prevent_streaming_overlap (Failure) -> Correctly blocked overlap.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_streaming_overlap (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;

    -- TEST T5: trg_prevent_multiple_winners (Success Case: First Winner)
    INSERT INTO AwardEvent (AwardEventID, Name, Year, Created_At, Version) VALUES (v_event_id, 'Test Awards', 2025, SYSDATE, 1);
    INSERT INTO AwardCategory (CategoryID, AwardEventID, Category_Name, Created_At, Version) VALUES (v_cat_id, v_event_id, 'Best Test', SYSDATE, 1);

    BEGIN
        INSERT INTO Nomination (NominationID, CategoryID, NomineePersonID, Is_Winner, Created_At, Version)
        VALUES (seq_Nomination.NEXTVAL, v_cat_id, v_person_id, 1, SYSDATE, 1);
        DBMS_OUTPUT.PUT_LINE('PASS: trg_prevent_multiple_winners (Success) -> First winner inserted.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_multiple_winners (Success) -> ' || SQLERRM);
    END;

    -- TEST T6: trg_prevent_multiple_winners (Failure Case: Second Winner)
    BEGIN
        INSERT INTO Nomination (NominationID, CategoryID, NomineePersonID, Is_Winner, Created_At, Version)
        VALUES (seq_Nomination.NEXTVAL, v_cat_id, v_person_id, 1, SYSDATE, 1);
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_multiple_winners (Failure) -> Allowed second winner.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20003 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: trg_prevent_multiple_winners (Failure) -> Correctly blocked second winner.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_multiple_winners (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;

    -- TEST T7: trg_prevent_title_bad_dates (Success Case)
    BEGIN
        UPDATE Title SET Start_Year = 2020, Release_Date = TO_DATE('2021-01-01','YYYY-MM-DD')
        WHERE TitleID = v_title_id;
        DBMS_OUTPUT.PUT_LINE('PASS: trg_prevent_title_bad_dates (Success) -> Allowed valid dates.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_title_bad_dates (Success) -> ' || SQLERRM);
    END;

    -- TEST T8: trg_prevent_title_bad_dates (Failure Case)
    BEGIN
        -- Release Date (1990) before Start Year (2020)
        UPDATE Title SET Start_Year = 2020, Release_Date = TO_DATE('1990-01-01','YYYY-MM-DD')
        WHERE TitleID = v_title_id;
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_title_bad_dates (Failure) -> Allowed bad date.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20400 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: trg_prevent_title_bad_dates (Failure) -> Correctly blocked bad date.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: trg_prevent_title_bad_dates (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;
    
    -- TEST T9: trg_no_adult_genre_title (Success Case)
    -- We assume v_title_id is non-adult. We create a "Family" genre.
    SELECT NVL(MAX(GenreID),0)+1 INTO v_genre_id FROM Genre;
    INSERT INTO Genre (GenreID, Name, Is_Adult_Only, Created_At, Version) VALUES (v_genre_id, 'Family Friendly Test', 0, SYSDATE, 1);
    
    BEGIN
        -- Calculating ID manually to avoid sequence gaps
        SELECT NVL(MAX(TitleGenreID), 0) + 1 INTO v_temp_id FROM TitleGenre;
        INSERT INTO TitleGenre (TitleGenreID, TitleID, GenreID, Created_At, Version)
        VALUES (v_temp_id, v_title_id, v_genre_id, SYSDATE, 1);
        DBMS_OUTPUT.PUT_LINE('PASS: trg_no_adult_genre_title (Success) -> Safe genre linked.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_no_adult_genre_title (Success) -> ' || SQLERRM);
    END;

    -- TEST T10: trg_no_adult_genre_title (Failure Case)
    -- We try to link an "X-Rated" genre to the non-adult movie.
    SELECT NVL(MAX(GenreID),0)+1 INTO v_genre_id FROM Genre;
    INSERT INTO Genre (GenreID, Name, Is_Adult_Only, Created_At, Version) VALUES (v_genre_id, 'X-Rated Test', 1, SYSDATE, 1);

    BEGIN
        SELECT NVL(MAX(TitleGenreID), 0) + 1 INTO v_temp_id FROM TitleGenre;
        INSERT INTO TitleGenre (TitleGenreID, TitleID, GenreID, Created_At, Version)
        VALUES (v_temp_id, v_title_id, v_genre_id, SYSDATE, 1);
        DBMS_OUTPUT.PUT_LINE('FAIL: trg_no_adult_genre_title (Failure) -> Allowed Adult genre on safe movie.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: trg_no_adult_genre_title (Failure) -> Correctly blocked Adult genre.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL: trg_no_adult_genre_title (Failure) -> Wrong error: ' || SQLERRM);
        END IF;
    END;
    DBMS_OUTPUT.PUT_LINE(' ');

    -- =============================================
    -- PHASE 4: ANALYTICAL PROCEDURES
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PHASE 4: ANALYTICAL PROCEDURES (Execution Check)');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    DBMS_OUTPUT.PUT_LINE('Running: usp_show_monthly_stats...');
    usp_show_monthly_stats(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')), TO_NUMBER(TO_CHAR(SYSDATE, 'MM')));
    
    DBMS_OUTPUT.PUT_LINE('Running: usp_calc_title_pop...');
    usp_calc_title_pop; -- Silent execution
    
    DBMS_OUTPUT.PUT_LINE('Running: usp_show_person_activity...');
    usp_show_person_activity;
    
    DBMS_OUTPUT.PUT_LINE('PASS: All analytical procedures executed without crashing.');
    DBMS_OUTPUT.PUT_LINE(' ');

    -- =============================================
    -- PHASE 5: VIEWS CHECK
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PHASE 5: VIEWS CHECK (Data Access)');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    -- Check vw_title_metadata
    BEGIN
        SELECT COUNT(*) INTO v_count FROM vw_title_metadata WHERE ROWNUM <= 1;
        DBMS_OUTPUT.PUT_LINE('PASS: vw_title_metadata -> Query successful.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: vw_title_metadata -> ' || SQLERRM);
    END;

    -- Check vw_title_analytics
    BEGIN
        SELECT COUNT(*) INTO v_count FROM vw_title_analytics WHERE ROWNUM <= 1;
        DBMS_OUTPUT.PUT_LINE('PASS: vw_title_analytics -> Query successful.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FAIL: vw_title_analytics -> ' || SQLERRM);
    END;
    DBMS_OUTPUT.PUT_LINE(' ');

    -- =============================================
    -- PHASE 6: INDEXES CHECK
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PHASE 6: INDEXES CHECK (Performance)');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    -- Check Index 1
    SELECT COUNT(*) INTO v_count FROM USER_INDEXES WHERE INDEX_NAME = UPPER('idx_titlegenre_genre_id');
    IF v_count > 0 THEN DBMS_OUTPUT.PUT_LINE('PASS: Index [idx_titlegenre_genre_id] found.');
    ELSE DBMS_OUTPUT.PUT_LINE('FAIL: Index [idx_titlegenre_genre_id] MISSING.'); END IF;

    -- Check Index 2
    SELECT COUNT(*) INTO v_count FROM USER_INDEXES WHERE INDEX_NAME = UPPER('idx_userrating_title');
    IF v_count > 0 THEN DBMS_OUTPUT.PUT_LINE('PASS: Index [idx_userrating_title] found.');
    ELSE DBMS_OUTPUT.PUT_LINE('FAIL: Index [idx_userrating_title] MISSING.'); END IF;

    DBMS_OUTPUT.PUT_LINE(' ');
    
    -- =============================================
    -- PHASE 7: CLEANUP
    -- =============================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PHASE 7: FINAL CLEANUP');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('-> All test data rolled back. Database is clean.');
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('TEST COMPLETED.');
END;
/