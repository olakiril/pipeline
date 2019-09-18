%{
# surgeries performed on mice
-> `common_mice`.`mice`
surgery_id                  : smallint                      # Unique number given to each surgery
---
date                        : date                          # YYYY-MM-DD Format. Date surgery was performed
time                        : time                          # Start of mouse recovery
-> experiment.Person
-> experiment.MouseRoom
-> experiment.SurgeryOutcome
-> experiment.SurgeryType
surgery_quality             : tinyint                       # 0-5 self-rating, 0 being worst and 5 best
ketoprofen=null             : decimal(4,3) unsigned         # Amount of Ketoprofen given to mouse
weight=null                 : decimal(5,2) unsigned         # Weight of mouse before surgery
surgery_notes               : varchar(256)                  # Notes on surgery
%}


classdef Surgery < dj.Manual
end