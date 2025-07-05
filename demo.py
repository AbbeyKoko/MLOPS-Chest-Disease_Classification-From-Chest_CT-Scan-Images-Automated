from src.cnnClassifier.logger import LoggerManager

LoggerManager("demo").get_logger().info("testing")
LoggerManager().get_logger().info("testing")
