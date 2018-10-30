--package.cpath = 'launcher.dll;' .. package.cpath
--libfuncs = require('launcher')
require('launcher');
pHost = (ReadLCCNCT(_SourceFolder.."\\lccnct.dta"));
pVtm = (ReadVTM(_SourceFolder.."\\vtm.brn"));
nVtm = (ReadVTM(_SourceFolder.."\\vtm.brn"));
SizeSelector = (false);
tblResolution = {"800_600", "1024_600", "1024_768", "1152_864", "1280_768", "1280_800", "1280_1024", "1360_768", "1366_768", "1440_900", "1536_864", "1600_900", "1680_1050", "1920_1080", "1920_1200", "2560_1080", "2560_1440", "3440_1440", "3840_2160", ""..System.GetDisplayInfo().Width.."_"..System.GetDisplayInfo().Height..""};

function LCUpdater(Host, Version)
	if(HTTP.TestConnection(Host.."launcher.xml", 20, 80, nil, nil) == false)then
		Button.SetEnabled("start", false);
		Button.SetEnabled("repair", false);
		TaskBarList.SetOverlayIcon(IDI_EXCLAMATION);
		Paragraph.SetText("Paragraph1", "Update Failure.");
		TaskBarList.SetProgressState(TBPF_ERROR);
		Dialog.Message("Error", "Cannot connect to server, try again later.", MB_OK, MB_ICONEXCLAMATION, MB_DEFBUTTON1);
		Window.Close(Application.GetWndHandle(), CLOSEWND_TERMINATE);
	else
		XML.SetXML(SubmitCheckMethod(Host.."launcher.xml"));
		local NumberOfUpdates = XML.GetAttribute("Launcher/launcher_settings", "game_version");
		local sUpdate = (false);
		if(tonumber(Version) ~= tonumber(NumberOfUpdates))then
			if(tonumber(Version) == tonumber(NumberOfUpdates))then
				sUpdate = (false);
			elseif(tonumber(Version) < tonumber(NumberOfUpdates))then
				sUpdate = (true);
			end
		else
			sUpdate = (false);
		end
		if(sUpdate == true)then
			Button.SetEnabled("start", false);
			Button.SetEnabled("repair", false);
			for Count = 1, tonumber(NumberOfUpdates) - tonumber(Version) do
				DownloadCheckMethod(XML.GetAttribute("Launcher/launcher_settings", "ip")..tonumber(nVtm) + 1 ..".zip", _SourceFolder.."\\"..tonumber(nVtm) + 1 ..".zip");
				Error = Application.GetLastError();
				if(Error == 0)then
					Zip.Extract(_SourceFolder.."\\"..tonumber(nVtm) + 1 ..".zip", {"*.*"}, _SourceFolder.."", true, true, "", ZIP_OVERWRITE_ALWAYS, ZipCallBack);
					Error = Application.GetLastError();
					if(Error == 0)then
						File.Delete(_SourceFolder.."\\"..tonumber(nVtm) + 1 ..".zip", false, false, false, nil);
						nVtm = (nVtm + 1);
					else
						Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
					end
				else
					Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
				end
			end
			WriteVTM(_SourceFolder.."\\vtm.brn", nVtm);
			Button.SetEnabled("start", true);
			Button.SetEnabled("repair", true);
			Paragraph.SetText("Paragraph1", "Update Completed!");
			TaskBarList.SetProgressValue(100, 100);
			TaskBarList.SetProgressState(TBPF_NOPROGRESS);
			Progress.SetCurrentPos("Progress1", 100);
			if(Application.LoadValue("lc_launcher", "startafterupdate") == "on")then
				Page.ClickObject("start");
			end
		elseif(sUpdate == false)then
			Button.SetEnabled("start", true);
			Button.SetEnabled("repair", true);
			Paragraph.SetText("Paragraph1", "Update Completed!");
			TaskBarList.SetProgressValue(100, 100);
			TaskBarList.SetProgressState(TBPF_NOPROGRESS);
			Progress.SetCurrentPos("Progress1", 100);
		end
	end
end

function DelimitedToTable(String, Delimiter)
	if not(Delimiter or #Delimiter < 1)then
		return nil
	end
	local tbl = {};
	local sa = String;
	local sD = '';
	local nP = string.find(sa, Delimiter, 1, true)
	while nP do
		sD = string.sub(sa, 1, nP-1)
		table.insert(tbl, #tbl+1, sD)
		sa = string.sub(sa, nP+1, -1)
		nP = string.find(sa, Delimiter, 1, true)
	end
	if(sa ~= '')then
		Table.Insert(tbl, #tbl+1, sa)
	end
	return tbl;
end

function SubmitCheckMethod(Url)
	if(String.Left(Url, 5) == "https")then
		return HTTP.SubmitSecure(Url, {}, SUBMITWEB_GET, 20, 443, nil, nil);
	else
		return HTTP.Submit(Url, {}, SUBMITWEB_GET, 20, 80, nil, nil);
	end
end

function DownloadCheckMethod(Url, Path)
	if(String.Left(Url, 5) == "https")then
		HTTP.DownloadSecure(Url, Path, MODE_BINARY, 20, 443, nil, nil, DownloadCallback);
	else
		HTTP.Download(Url, Path, MODE_BINARY, 20, 80, nil, nil, DownloadCallback);
	end
end

function DownloadCallback(nDownloaded, nTotal, nTransferRate, SecondLeft, SecondsLeftFormat, Message)
	if(nTotal ~= 0)then
	    --Convert total and downloaded bytes into formatted strings
	    local sDownloaded = String.GetFormattedSize(nDownloaded, FMTSIZE_AUTOMATIC, true);
	    local sTotal = String.GetFormattedSize(nTotal, FMTSIZE_AUTOMATIC, true);
	    local DownloadTransferRate = String.GetFormattedSize(nTransferRate*100.0, FMTSIZE_MB, true);
	    --Returns
	    local DownloadTimeLeft = ("Time Left: "..SecondsLeftFormat);
	    local Downloaded = ("Downloaded: "..sDownloaded.."/"..sTotal);
	    --Set meter position (fraction downloaded * max meter range)
	    local DownloadProgress = (nDownloaded / nTotal * 100);
	    Paragraph.SetText("Paragraph1", DownloadTimeLeft.." - "..Downloaded.." - "..DownloadTransferRate);
	    Progress.SetCurrentPos("Progress1", DownloadProgress);
	    TaskBarList.SetProgressValue(DownloadProgress, 100);
	else
	    Progress.SetCurrentPos("Progress1", 100);
	    TaskBarList.SetProgressState(TBPF_NOPROGRESS);
    end
end

function ZipCallBack(File, Percent, Status)
	if(Status == ZIP_STATUS_MAJOR)then
		Progress.SetCurrentPos("Progress1", Percent);
		TaskBarList.SetProgressState(TBPF_INDETERMINATE);
	else
		TaskBarList.SetProgressState(TBPF_INDETERMINATE);
		Progress.SetCurrentPos("Progress1", Percent);
		local sFile = String.SplitPath(File);
		Paragraph.SetText("Paragraph1", "Decompressing: "..sFile.Folder..sFile.Filename..sFile.Extension);
	end
	
	if(Abort)then
		return false;
	else
		return true;
	end
end

function Repair(Host)
	if(HTTP.TestConnection(Host, 20, 80, nil, nil) == false)then
		TaskBarList.SetOverlayIcon(IDI_EXCLAMATION);
		TaskBarList.SetProgressState(TBPF_ERROR);
		Paragraph.SetText("Paragraph1", "Cannot connect to server, try again later.");
		TaskBarList.SetOverlayIcon(IDI_NONE);
		TaskBarList.SetProgressState(TBPF_NOPROGRESS);
	else
		local Status = (true);
		XML.SetXML(SubmitCheckMethod(Host.."launcher.xml"));
		for Count = 1, XML.Count("Launcher", "*") do
			if(File.DoesExist(XML.GetAttribute("Launcher/file:"..Count, "path")..XML.GetValue("Launcher/file:"..Count)))then
				if(XML.GetAttribute("Launcher/file:"..Count, "checksum") ~= Crypto.MD5DigestFromFile(XML.GetAttribute("Launcher/file:"..Count, "path")..XML.GetValue("Launcher/file:"..Count)))then
					Status = (false);
				end
			else
				Status = (false);
			end
			if(Status == false)then
				Button.SetEnabled("start", false);
				Button.SetEnabled("repair", false);
				Paragraph.SetText("Paragraph1", "Scanning...");
				DownloadCheckMethod(XML.GetAttribute("Launcher/file:"..Count, "url"), _SourceFolder.."\\"..XML.GetAttribute("Launcher/file:"..Count, "path")..XML.GetValue("Launcher/file:"..Count));
				Error = Application.GetLastError();
				if(Error ~= 0)then
					Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
				end
			end
		end
		Error = Application.GetLastError();
		if(Error == 0)then
			Button.SetEnabled("start", true);
			Button.SetEnabled("repair", true);
			Paragraph.SetText("Paragraph1", "Update Completed");
			TaskBarList.SetProgressValue(100, 100);
			TaskBarList.SetProgressState(TBPF_NOPROGRESS);
			Progress.SetCurrentPos("Progress1", 100);
		else
			Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
			TaskBarList.SetProgressState(TBPF_ERROR);
			Button.SetEnabled("repair", true);
		end
	end
end

function LauncherUpdate(Host)
	XML.SetXML(SubmitCheckMethod(Host.."launcher.xml"));
	if(XML.GetAttribute("Launcher/launcher_settings", "launcher_version") ~= "")then
		if(File.GetVersionInfo(_SourceFolder.."\\".._SourceFilename).FileVersion < XML.GetAttribute("Launcher/launcher_settings", "launcher_version"))then
			if(File.GetVersionInfo(_SourceFolder.."\\".._SourceFilename).FileVersion ~= XML.GetAttribute("Launcher/launcher_settings", "launcher_version"))then
				Window.Minimize(Application.GetWndHandle());
				Dialog.Message("Notice", "There is an update and it is necessary to restart...", MB_OK, MB_ICONINFORMATION, MB_DEFBUTTON1);
				DownloadCheckMethod(XML.GetAttribute("Launcher/launcher_settings", "launcher_update_url"), _TempFolder.."\\LauncherUpdate.zip");
				Zip.Extract(_TempFolder.."\\LauncherUpdate.zip", {"*.*"}, _TempFolder.."\\launcherupdate\\", true, true, "", ZIP_OVERWRITE_ALWAYS, ZipCallBack);
				TextFile.WriteFromString(_TempFolder..'\\MoveUpdate.bat', [[
					@ECHO OFF
					title MoveUpdate
					timeout /t 5
					move ]]..'"'.._TempFolder..'\\launcherupdate\\*" "'.._SourceFolder..'"\r\n'..[[
					start]]..' "" "'.._SourceFolder.."\\".._SourceFilename..'"\r\n'..[[
					del ]]..'"'.._TempFolder..'\\launcherupdate*" /s /q\r\n'..[[
					rmdir ]]..'"'.._TempFolder..'\\launcherupdate"\r\n'..[[
					del "%~f0"
				]], false);
				Dialog.Message("Notice", "The application is updated in the background, this may take a few minutes. press [OK] to continue", MB_OK, MB_ICONINFORMATION, MB_DEFBUTTON1);
				Window.Minimize(Application.GetWndHandle());
				File.Run(_TempFolder..'\\MoveUpdate.bat', '', '', SW_HIDE, false);
				Application.Exit(0);
			end
		end
	end
end
