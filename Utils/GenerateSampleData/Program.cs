using System.Globalization;
using CsvHelper;
using Faker;

namespace GenerateSampleData
{
    class Program
    {

        static void Main(string[] args)
        {
            int userCount = 100000;
            int days = 30;
            string filePath = "C:\\Users\\alexgrover\\source\\repos\\mgdc-copilot-dashboard\\GeneratedData";

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
                    reportItem.Windows = Faker.Boolean.Random();
                    reportItem.Mac = Faker.Boolean.Random();
                    reportItem.Mobile = Faker.Boolean.Random();
                    reportItem.Web = Faker.Boolean.Random();
                    reportItem.Outlook = Faker.Boolean.Random();
                    reportItem.Word = Faker.Boolean.Random();
                    reportItem.Excel = Faker.Boolean.Random();
                    reportItem.PowerPoint = Faker.Boolean.Random();
                    reportItem.OneNote = Faker.Boolean.Random();
                    reportItem.Teams = Faker.Boolean.Random();
                    reportItem.OutlookWindows = Faker.Boolean.Random();
                    reportItem.WordWindows = Faker.Boolean.Random();
                    reportItem.ExcelWindows = Faker.Boolean.Random();
                    reportItem.PowerPointWindows = Faker.Boolean.Random();
                    reportItem.OneNoteWindows = Faker.Boolean.Random();
                    reportItem.TeamsWindows = Faker.Boolean.Random();
                    reportItem.OutlookMac = Faker.Boolean.Random();
                    reportItem.WordMac = Faker.Boolean.Random();
                    reportItem.ExcelMac = Faker.Boolean.Random();
                    reportItem.PowerPointMac = Faker.Boolean.Random();
                    reportItem.OneNoteMac = Faker.Boolean.Random();
                    reportItem.TeamsMac = Faker.Boolean.Random();
                    reportItem.OutlookMobile = Faker.Boolean.Random();
                    reportItem.WordMobile = Faker.Boolean.Random();
                    reportItem.ExcelMobile = Faker.Boolean.Random();
                    reportItem.PowerPointMobile = Faker.Boolean.Random();
                    reportItem.OneNoteMobile = Faker.Boolean.Random();
                    reportItem.TeamsMobile = Faker.Boolean.Random();
                    reportItem.OutlookWeb = Faker.Boolean.Random();
                    reportItem.WordWeb = Faker.Boolean.Random();
                    reportItem.ExcelWeb = Faker.Boolean.Random();
                    reportItem.PowerPointWeb = Faker.Boolean.Random();
                    reportItem.OneNoteWeb = Faker.Boolean.Random();
                    reportItem.TeamsWeb = Faker.Boolean.Random();

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