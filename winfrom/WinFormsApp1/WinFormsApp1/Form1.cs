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
            webBrowser.Dock = DockStyle.Fill; // 让 WebBrowser 控件填充整个窗体
            this.Controls.Add(webBrowser);
            webBrowser.Navigate("https://ataobc.com/@autojs/huiyuandaohang.html"); // 将 URL 替换为你想加载的网页
        }
    }
}
