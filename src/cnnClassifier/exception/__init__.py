import os
import sys

def error_message_detail(error, error_details:sys):
    type,value, excep_traceback = error_details.exc_info()
    file_name = excep_traceback.tb_frame.f_code.co_filename
    error_message = "Error occured python script [{0}] line number [{1}] error message [{2}]".format(
        file_name, excep_traceback.tb_lineno, str(error)
    )
    
    return error_message

class USvisaException(Exception):
    def __init__(self, error_message, error_details):
        """
        :param error_message: error message in string format
        """
        super().__init__(error_message)
        self.error_message = error_message_detail(
            error_message, error_details=error_details
        )
        
    def __str__(self):
        return self.error_message

