namespace PlyFileProcessor.Services
{
    /// <summary>
    /// PLY文件服务接口
    /// </summary>
    public interface IPlyFileService
    {
        /// <summary>
        /// 检查并处理PLY文件
        /// </summary>
        /// <param name="taskId">任务ID</param>
        /// <param name="projectName">项目名称</param>
        /// <returns>是否找到并处理了PLY文件</returns>
        Task<bool> CheckAndProcessPlyFilesAsync(string taskId, string projectName, string path);

        /// <summary>
        /// 获取PLY检查路径
        /// </summary>
        /// <returns>PLY文件检查路径</returns>
        string GetPlyCheckPath();
    }



}