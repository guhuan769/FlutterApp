using Microsoft.AspNetCore.Mvc;

namespace BackendInterface.Controllers
{
    /// <summary>
    /// 测试控制器
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        /// <summary>
        /// 获取测试信息
        /// </summary>
        /// <returns>简单的测试信息</returns>
        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { message = "API正常工作!" });
        }
    }
} 