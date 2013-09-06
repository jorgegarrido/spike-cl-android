-define(LOG_INFO(Log, Args), io:format("(~p) ~s [spike-log] "++Log++"\n", [self(), ?DATE_LOG | Args])).
-define(DATE_LOG, rehc_mydilo_utils:formatted_date()++" "++rehc_mydilo_utils:formatted_time()).

