namespace WinFormsApp1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            InitializeWebBrowser();
        }

        private void InitializeWebBrowser()
        {
            WebBrowser webBrowser = new WebBrowser();
            webBrowser.Dock = DockStyle.Fill; // �� WebBrowser �ؼ������������
            this.Controls.Add(webBrowser);
            webBrowser.Navigate("https://ataobc.com/@autojs/huiyuandaohang.html"); // �� URL �滻Ϊ������ص���ҳ
        }
    }
}
