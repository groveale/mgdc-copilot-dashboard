using CsvHelper.Configuration.Attributes;

public class UserDetailReportTruncItem
{
    [Name("Report Refresh Date")]
    public string ReportRefreshDate { get; set; }
    [Name("User Principal Name")]
    public string UserPrincipalName { get; set; }
    [Name("Display Name")]
    public string DisplayName { get; set; }
    [Name("Assigned Products")]
    public string AssignedProducts { get; set; }
}