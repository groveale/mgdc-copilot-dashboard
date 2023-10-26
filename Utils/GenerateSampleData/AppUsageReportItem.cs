using CsvHelper.Configuration.Attributes;
public class AppUsageReportItem
{
    [Name("Report Refresh Date")]
    public string ReportRefreshDate { get; set; }
    [Name("User Principal Name")]
    public string UserPrincipalName { get; set; }
    [Name("Last Activation Date")]
    public string LastActivationDate { get; set; }
    [Name("Last Activity Date")]
    public string LastActivityDate { get; set; }
    [Name("Report Period")]
    public int ReportPeriod { get; set; }
    public bool Windows { get; set; }
    public bool Mac { get; set; }
    public bool Mobile { get; set; }
    public bool Web { get; set; }
    public bool Outlook { get; set; }
    public bool Word { get; set; }
    public bool Excel { get; set; }
    public bool PowerPoint { get; set; }
    public bool OneNote { get; set; }
    public bool Teams { get; set; }
    [Name("Outlook (Windows)")]
    public bool OutlookWindows { get; set; }
    [Name("Word (Windows)")]
    public bool WordWindows { get; set; }
    [Name("Excel (Windows)")]
    public bool ExcelWindows { get; set; }
    [Name("PowerPoint (Windows)")]
    public bool PowerPointWindows { get; set; }
    [Name("OneNote (Windows)")]
    public bool OneNoteWindows { get; set; }
    [Name("Teams (Windows)")]
    public bool TeamsWindows { get; set; }
    [Name("Outlook (Mac)")]
    public bool OutlookMac { get; set; }
    [Name("Word (Mac)")]
    public bool WordMac { get; set; }
    [Name("Excel (Mac)")]
    public bool ExcelMac { get; set; }
    [Name("PowerPoint (Mac)")]
    public bool PowerPointMac { get; set; }
    [Name("OneNote (Mac)")]
    public bool OneNoteMac { get; set; }
    [Name("Teams (Mac)")]
    public bool TeamsMac { get; set; }
    [Name("Outlook (Mobile)")]
    public bool OutlookMobile { get; set; }
    [Name("Word (Mobile)")]
    public bool WordMobile { get; set; }
    [Name("Excel (Mobile)")]
    public bool ExcelMobile { get; set; }
    [Name("PowerPoint (Mobile)")]
    public bool PowerPointMobile { get; set; }
    [Name("OneNote (Mobile)")]
    public bool OneNoteMobile { get; set; }
    [Name("Teams (Mobile)")]
    public bool TeamsMobile { get; set; }
    [Name("Outlook (Web)")]
    public bool OutlookWeb { get; set; }
    [Name("Word (Web)")]
    public bool WordWeb { get; set; }
    [Name("Excel (Web)")]
    public bool ExcelWeb { get; set; }
    [Name("PowerPoint (Web)")]
    public bool PowerPointWeb { get; set; }
    [Name("OneNote (Web)")]
    public bool OneNoteWeb { get; set; }
    [Name("Teams (Web)")]
    public bool TeamsWeb { get; set; }
}