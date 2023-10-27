using System.Globalization;
using CsvHelper;
using Faker;

namespace GenerateSampleData
{
    class Program
    {

        static void Main(string[] args)
        {
            int userCount = 1000;
            int days = 30;
            string filePath = "C:\\Users\\alexgrover\\source\\repos\\mgdc-copilot-dashboard\\GeneratedData\\1K";

            var today = DateTime.Now;

            var usersList = new List<UserDetailReportTruncItem>();
            for (int i = 0; i < userCount; i++)
            {
                var fakeName = $"{Name.FullName(NameFormats.Standard)}";
                var fakeEmail = $"{Internet.UserName(fakeName)}@groverale.onmicrosoft.com";
                if (i % 1000 == 0)
                {
                    Console.WriteLine($"Adding {fakeEmail} to the list... {i} / {userCount}");
                }
                usersList.Add(new UserDetailReportTruncItem()
                {
                    ReportRefreshDate = today.ToString("yyyy-MM-dd"),
                    UserPrincipalName = fakeEmail,
                    DisplayName = fakeName,
                    AssignedProducts = "Microsoft 365 E5"
                });
            }

            var userReportFileName = $"{filePath}\\M365UserDetailReport-{today.ToString("yyyy-MM-dd")}.csv";
            Console.WriteLine($"Writing {userReportFileName}");
            using (var writer = new StreamWriter(userReportFileName))
            using (var csv = new CsvWriter(writer, CultureInfo.InvariantCulture))
            {
                csv.WriteRecords(usersList);
            }
            

            // loop for each day
            for (int i = 0; i < days; i++)
            {
                var reportDate = today.AddDays(-i);
                var reportDateFormatted = reportDate.ToString("yyyy-MM-dd");

                var reportData = new List<AppUsageReportItem>();

                // loop for each user
                foreach (var user in usersList)
                {
                    var reportItem = new AppUsageReportItem();
                    reportItem.ReportRefreshDate = reportDate.ToString("yyyy-MM-dd");
                    reportItem.UserPrincipalName = user.UserPrincipalName;
                    reportItem.LastActivationDate = reportDate.AddDays(-i).ToString("yyyy-MM-dd");
                    reportItem.LastActivityDate = reportDate.AddDays(-i).ToString("yyyy-MM-dd");
                    reportItem.ReportPeriod = 30;
                    reportItem.Windows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Mac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Mobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Web = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Outlook = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Word = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Excel = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.PowerPoint = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OneNote = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.Teams = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OutlookWindows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.WordWindows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.ExcelWindows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.PowerPointWindows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OneNoteWindows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.TeamsWindows = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OutlookMac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.WordMac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.ExcelMac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.PowerPointMac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OneNoteMac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.TeamsMac = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OutlookMobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.WordMobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.ExcelMobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.PowerPointMobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OneNoteMobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.TeamsMobile = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OutlookWeb = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.WordWeb = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.ExcelWeb = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.PowerPointWeb = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.OneNoteWeb = Faker.Boolean.Random() ? "Yes" : "No";
                    reportItem.TeamsWeb = Faker.Boolean.Random() ? "Yes" : "No";

                    reportData.Add(reportItem);
                }

                var fileName = $"{filePath}\\M365AppUserReport-{reportDateFormatted}.csv";
                Console.WriteLine($"Writing {fileName}");
                using (var writer = new StreamWriter(fileName))
                using (var csv = new CsvWriter(writer, CultureInfo.InvariantCulture))
                {
                    
                    csv.WriteRecords(reportData);
                }
            }

        }
    }
}