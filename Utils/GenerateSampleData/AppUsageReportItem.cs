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
    public string Windows { get; set; }
    public string Mac { get; set; }
    public string Mobile { get; set; }
    public string Web { get; set; }
    public string Outlook { get; set; }
    public string Word { get; set; }
    public string Excel { get; set; }
    public string PowerPoint { get; set; }
    public string OneNote { get; set; }
    public string Teams { get; set; }
    [Name("Outlook (Windows)")]
    public string OutlookWindows { get; set; }
    [Name("Word (Windows)")]
    public string WordWindows { get; set; }
    [Name("Excel (Windows)")]
    public string ExcelWindows { get; set; }
    [Name("PowerPoint (Windows)")]
    public string PowerPointWindows { get; set; }
    [Name("OneNote (Windows)")]
    public string OneNoteWindows { get; set; }
    [Name("Teams (Windows)")]
    public string TeamsWindows { get; set; }
    [Name("Outlook (Mac)")]
    public string OutlookMac { get; set; }
    [Name("Word (Mac)")]
    public string WordMac { get; set; }
    [Name("Excel (Mac)")]
    public string ExcelMac { get; set; }
    [Name("PowerPoint (Mac)")]
    public string PowerPointMac { get; set; }
    [Name("OneNote (Mac)")]
    public string OneNoteMac { get; set; }
    [Name("Teams (Mac)")]
    public string TeamsMac { get; set; }
    [Name("Outlook (Mobile)")]
    public string OutlookMobile { get; set; }
    [Name("Word (Mobile)")]
    public string WordMobile { get; set; }
    [Name("Excel (Mobile)")]
    public string ExcelMobile { get; set; }
    [Name("PowerPoint (Mobile)")]
    public string PowerPointMobile { get; set; }
    [Name("OneNote (Mobile)")]
    public string OneNoteMobile { get; set; }
    [Name("Teams (Mobile)")]
    public string TeamsMobile { get; set; }
    [Name("Outlook (Web)")]
    public string OutlookWeb { get; set; }
    [Name("Word (Web)")]
    public string WordWeb { get; set; }
    [Name("Excel (Web)")]
    public string ExcelWeb { get; set; }
    [Name("PowerPoint (Web)")]
    public string PowerPointWeb { get; set; }
    [Name("OneNote (Web)")]
    public string OneNoteWeb { get; set; }
    [Name("Teams (Web)")]
    public string TeamsWeb { get; set; }
}