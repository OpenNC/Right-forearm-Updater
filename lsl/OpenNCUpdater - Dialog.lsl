////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           OpenNCUpdater - Dialog                               //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ©   2013 - 2014  OpenNC                                                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////
//an adaptation of Schmobag Hogfather's SchmoDialog script
//MESSAGE MAP
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer iPagesize = 12;
string MORE = "►";
string PREV = "◄";
string UPMENU = "BACK"; // string to identify the UPMENU button in the utility lButtons
string BLANK = " ";
integer g_iTimeOut = 300;
integer g_iReapeat = 5;//how often the timer will go off, in seconds
list g_lMenus;//9-strided list in form listenChan, dialogid, listener, starttime, recipient, prompt, list buttons, utility buttons, currentpage
//where "list buttons" means the big list of choices presented to the user
//and "page buttons" means utility buttons that will appear on every page, such as one saying "go up one level"
//and "currentpage" is an integer meaning which page of the menu the user is currently viewing
list g_lRemoteMenus;
integer g_iStrideLength = 9;
key g_kWearer;

Notify(key kID, string sMsg, integer nAlsoNotifyWearer)
{
    if (kID == g_kWearer)
        llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID) != ZERO_VECTOR)
            llRegionSayTo(kID,0,sMsg);
        else
            llInstantMessage(kID, sMsg);
        if (nAlsoNotifyWearer == TRUE)
            llOwnerSay(sMsg);
    }
}

list CharacterCountCheck(list lIn, key ID)
// checks if any of the times is over 24 characters and removes them if needed
{
    list lOut;
    string s;
    integer i;
    integer m=llGetListLength(lIn);
    for (i=0;i<m;i++)
    {
        s=llList2String(lIn,i);
        if (llStringLength(s)>24)
            Notify(ID, "The following button is longer than 24 characters and has been removed (can be caused by the name length of the item in the collars inventory): "+s, TRUE);
        else
            lOut+=[s];
    }
    return lOut;
}


integer RandomUniqueChannel()
{
    integer iOut = llRound(llFrand(10000000)) + 100000;
    if (~llListFindList(g_lMenus, [iOut]))
        iOut = RandomUniqueChannel();
    return iOut;
}

Dialog(key kRecipient, string sPrompt, list lMenuItems, list lUtilityButtons, integer iPage, key kID)
{
    string sThisPrompt;
    list lButtons;
    list lCurrentItems;
    integer iNumitems = llGetListLength(lMenuItems);
    integer iStart;
    integer iMyPageSize = iPagesize - llGetListLength(lUtilityButtons);
    //slice the menuitems by page
    if (iNumitems > iMyPageSize)
    {
        iMyPageSize=iMyPageSize-2;//we'll use two slots for the MORE and PREV button, so shrink the page accordingly
        iStart = iPage * iMyPageSize;
        integer iEnd = iStart + iMyPageSize - 1;
        //multi page menu
        //lCurrentItems = llList2List(lMenuItems, iStart, iEnd);
        lButtons = llList2List(lMenuItems, iStart, iEnd);
        sThisPrompt = sThisPrompt + " Page "+(string)(iPage+1)+"/"+(string)(((iNumitems-1)/iMyPageSize)+1);
    }
    else
    {
        iStart = 0;
        lButtons = lMenuItems;
    }
    // check promt lenghtes
    integer iPromptlen=llStringLength(sPrompt);
    if (iPromptlen>511)
    {
        Notify(kRecipient,"The dialog prompt message is longer than 512 characters. It will be truncated to 512 characters.",TRUE);
        sPrompt=llGetSubString(sPrompt,0,510);
        sThisPrompt = sPrompt;
    }
    else if (iPromptlen + llStringLength(sThisPrompt)< 512)
        sThisPrompt= sPrompt + sThisPrompt;
    else
        sThisPrompt= sPrompt;
    lButtons = SanitizeButtons(lButtons);
    lUtilityButtons = SanitizeButtons(lUtilityButtons);
    integer iChan = RandomUniqueChannel();
    integer g_iListener = llListen(iChan, "", kRecipient, "");
    llSetTimerEvent(g_iReapeat);
    if (iNumitems > iMyPageSize)
        llDialog(kRecipient, sThisPrompt, PrettyButtons(lButtons, lUtilityButtons,[PREV,MORE]), iChan);
    else
        llDialog(kRecipient, sThisPrompt, PrettyButtons(lButtons, lUtilityButtons,[]), iChan);
    integer ts = llGetUnixTime() + g_iTimeOut;
    g_lMenus += [iChan, kID, g_iListener, ts, kRecipient, sPrompt, llDumpList2String(lMenuItems, "|"), llDumpList2String(lUtilityButtons, "|"), iPage];
}

list SanitizeButtons(list lIn)
{
    integer iLength = llGetListLength(lIn);
    integer n;
    for (n = iLength - 1; n >= 0; n--)
    {
        integer type = llGetListEntryType(lIn, n);
        if (llList2String(lIn, n) == "") //remove empty sStrings
            lIn = llDeleteSubList(lIn, n, n);
        else if (type != TYPE_STRING)        //cast anything else to string
            lIn = llListReplaceList(lIn, [llList2String(lIn, n)], n, n);
    }
    return lIn;
}

list PrettyButtons(list lOptions, list lUtilityButtons, list iPagebuttons)
{//returns a list formatted to that "options" will start in the top left of a dialog, and "utilitybuttons" will start in the bottom right
    list lSpacers;
    list lCombined = lOptions + lUtilityButtons + iPagebuttons;
    while (llGetListLength(lCombined) % 3 != 0 && llGetListLength(lCombined) < 12)
    {
        lSpacers += [BLANK];
        lCombined = lOptions + lSpacers + lUtilityButtons + iPagebuttons;
    }
    // check if a UPBUTTON is present and remove it for the moment
    integer u = llListFindList(lCombined, [UPMENU]);
    if (u != -1)
        lCombined = llDeleteSubList(lCombined, u, u);
    list lOut = llList2List(lCombined, 9, 11);
    lOut += llList2List(lCombined, 6, 8);
    lOut += llList2List(lCombined, 3, 5);
    lOut += llList2List(lCombined, 0, 2);
    //make sure we move UPMENU to the lower right corner
    if (u != -1)
        lOut = llListInsertList(lOut, [UPMENU], 2);
    return lOut;    
}

list RemoveMenuStrkIDe(list lMenu, integer iIndex)
{
    //tell this function the menu you wish to remove, identified by list index
    //it will close the listener, remove the menu's entry from the list, and return the new list
    //should be called in the listen event, and on menu timeout    
    integer g_iListener = llList2Integer(lMenu, iIndex + 2);
    llListenRemove(g_iListener);
    return llDeleteSubList(lMenu, iIndex, iIndex + g_iStrideLength - 1);
}

CleanList()
{
    //loop through menus and remove any whose timeouts are in the past
    //start at end of list and loop down so that indices don't get messed up as we remove items
    integer iLength = llGetListLength(g_lMenus);
    integer n;
    integer iNow = llGetUnixTime();
    for (n = iLength - g_iStrideLength; n >= 0; n -= g_iStrideLength)
    {
        integer iDieTime = llList2Integer(g_lMenus, n + 3);
        if (iNow > iDieTime)
        {              
            key kID = llList2Key(g_lMenus, n + 1);
            llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", kID);
            g_lMenus = RemoveMenuStrkIDe(g_lMenus, n);
        }
    } 
}

ClearUser(key kRCPT)
{//find any strides belonging to user and remove them
    integer iIndex = llListFindList(g_lMenus, [kRCPT]);
    while (~iIndex)
    {
        g_lMenus = llDeleteSubList(g_lMenus, iIndex - 4, iIndex - 5 + g_iStrideLength);
        iIndex = llListFindList(g_lMenus, [kRCPT]);
    }
}

integer InSim(key id)
{
    return llKey2Name(id) != "";
}

default
{    
    state_entry()
    {
        g_kWearer=llGetOwner();
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == DIALOG)
        {//give a dialog with the options on the button labels
            //str will be pipe-delimited list with rcpt|prompt|page|backtick-delimited-list-buttons|backtick-delimited-utility-buttons
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kRCPT = (key)llList2String(lParams, 0);
            integer iIndex = llListFindList(g_lRemoteMenus, [kRCPT]);
            if (~iIndex)
            {
                if (!InSim(kRCPT))
                {
                    llHTTPRequest(llList2String(g_lRemoteMenus, iIndex+1), [HTTP_METHOD, "POST"], sStr+"|"+(string)kID);
                    return;
                }
                else
                    g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [], iIndex, iIndex+1);
            }
            string sPrompt = llList2String(lParams, 1);
            integer iPage = (integer)llList2String(lParams, 2);
            list lbuttons = CharacterCountCheck(llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []), kRCPT);
            list ubuttons = llParseString2List(llList2String(lParams, 4), ["`"], []);        
            //first clean out any strides already in place for that user.  prevents having lots of listens open if someone uses the menu several times while sat
            ClearUser(kRCPT);
            //now give the dialog and save the new stride
            Dialog(kRCPT, sPrompt, lbuttons, ubuttons, iPage, kID);
        }
        else if (llGetSubString(sStr, 0, 10) == "remotemenu:")
        {
            if (iNum == COMMAND_OWNER || iNum == COMMAND_SECOWNER)
            {
                string sCmd = llGetSubString(sStr, 11, -1);
                if (llGetSubString(sCmd, 0, 3) == "url:")
                {
                    integer iIndex = llListFindList(g_lRemoteMenus, [kID]);
                    if (~iIndex)
                        g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [kID, llGetSubString(sCmd,  4, -1)], iIndex, iIndex+1);
                    else
                        g_lRemoteMenus += [kID, llGetSubString(sCmd, 4, -1)];
                    llMessageLinked(LINK_SET, iNum, "menu", kID);
                }
                else if (llGetSubString(sCmd, 0, 2) == "off")
                {
                    integer iIndex = llListFindList(g_lRemoteMenus, [kID]);
                    if (~iIndex)
                        g_lRemoteMenus = llListReplaceList((g_lRemoteMenus = []) + g_lRemoteMenus, [], iIndex, iIndex+1);
                }
                else if (llGetSubString(sCmd, 0, 8) == "response:")
                {
                    list lParams = llParseString2List(llGetSubString(sCmd, 9, -1), ["|"], []);
                    //llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)kAv + "|" + sMessage + "|" + (string)iPage, kMenuID);
                    llMessageLinked(LINK_SET, DIALOG_RESPONSE, llList2String(lParams, 0) + "|" + llList2String(lParams, 1) + "|" + llList2String(lParams, 2), llList2String(lParams, 3));
                }
                else if (llGetSubString(sCmd, 0, 7) == "timeout:")
                    llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", llGetSubString(sCmd, 8, -1));
            }
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMessage)
    {
        integer iMenuIndex = llListFindList(g_lMenus, [iChan]);
        if (~iMenuIndex)
        {
            key kMenuID = llList2Key(g_lMenus, iMenuIndex + 1);
            key kAv = llList2Key(g_lMenus, iMenuIndex + 4);
            string sPrompt = llList2String(g_lMenus, iMenuIndex + 5);            
            list items = llParseStringKeepNulls(llList2String(g_lMenus, iMenuIndex + 6), ["|"], []);
            list ubuttons = llParseStringKeepNulls(llList2String(g_lMenus, iMenuIndex + 7), ["|"], []);
            integer iPage = llList2Integer(g_lMenus, iMenuIndex + 8);    
            g_lMenus = RemoveMenuStrkIDe(g_lMenus, iMenuIndex);       
            if (sMessage == MORE)
            {//increase the page num and give new menu
                iPage++;
                integer thisiPagesize = iPagesize - llGetListLength(ubuttons) - 2;
                if (iPage * thisiPagesize >= llGetListLength(items))
                    iPage = 0;
                Dialog(kID, sPrompt, items, ubuttons, iPage, kMenuID);
            }
            else if (sMessage == PREV)
            {//increase the page num and give new menu
                iPage--;
                if (iPage < 0)
                {
                    integer thisiPagesize = iPagesize - llGetListLength(ubuttons) - 2;
                    iPage = (llGetListLength(items)-1)/thisiPagesize;
                }
                Dialog(kID, sPrompt, items, ubuttons, iPage, kMenuID);
            }
            else if (sMessage == BLANK)
                Dialog(kID, sPrompt, items, ubuttons, iPage, kMenuID);
            else
                llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)kAv + "|" + sMessage + "|" + (string)iPage, kMenuID);
        }
    }
    
    timer()
    {
        CleanList();    
        //if list is empty after that, then stop timer
        if (!llGetListLength(g_lMenus))
            llSetTimerEvent(0.0);
    }
}