-define(LOG_INFO(Log, Args), io:format("(~p) [spike-log] "++Log++"\n", [self() | Args])).
