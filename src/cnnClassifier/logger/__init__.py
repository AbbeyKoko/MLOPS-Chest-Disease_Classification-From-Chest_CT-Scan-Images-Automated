import os
import logging
from datetime import datetime
from from_root import from_root


class LoggerManager:
    """ 
    Class Name     : LoggerManager
    Description    : This logger class sets up a logger including timestamps, class name, method name and line numbers 
    
    Usage          : Inside Class -> logger = LoggerManager("MyClassName").get_logger()
                    Outside Class -> logger = LoggerManager(__name___).get_logger()
    """
    
    def __init__(self, logger_name: str = None, log_dir : str = "logs", level: int = logging.DEBUG) -> None:
      self.logger_name = logger_name or __name__
      self.log_dir = log_dir
      self.level = level
      self.logger = None
      self._configure_logger()
      # self.get_logger() 
      
    
    def _configure_logger(self) -> None:
        """ 
        Configure the logger to handle both file and console/stream handlers
        """
        
        LOG_FILE = f"{datetime.now().strftime('%m_%d_%Y_%H_%M_%S')}.log"
        logs_dir = os.path.join(from_root(), self.log_dir)
        os.makedirs(logs_dir, exist_ok=True)
        
        logs_path = os.path.join(logs_dir, LOG_FILE)
        
        self.logger = logging.getLogger(self.logger_name)
        self.logger.setLevel(self.level)
        
        if self.logger.handlers:
            return
        
        formatter = logging.Formatter(
            "[%(asctime)s] %(name)s - %(funcName)s:%(lineno)d - %(levelname)s - %(message)s",
            "%Y-%m-%d %H:%M:%S"
        )
        
        # File Handler
        file_handler = logging.FileHandler(logs_path)
        file_handler.setFormatter(formatter)
        
        # Stream/Console Handler
        stream_handler = logging.StreamHandler()
        stream_handler.setFormatter(formatter)
        
        self.logger.addHandler(file_handler)
        self.logger.addHandler(stream_handler)
        
    def get_logger(self) -> logging.Logger:
        """
        Return the configured logger
        """
        return self.logger