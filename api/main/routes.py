import time
from datetime import datetime

from . import bp

@bp.get("/time")
def get_current_time():
    return {"time": time.time()}

@bp.get("/date")
def get_current_date():
    return {"date": datetime.now().strftime("%Y-%m-%d")}

