{application, spike,
 [
  {description, "SPIKE - Client For Android"},
  {vsn, "1.9"},
  {modules, [spike_app, spike_sup, spike_agent]},
  {registered, [spike_app, spike_sup, spike_agent]},
  {applications,[ kernel, stdlib]},
  {mod, { spike_app, []}},

  %%
  %% This section is intended for environment variables of spike-client startup.
  %% You can override this values if spike-client is included from another app.
  %%
  {env, [{cs_node, 'cs_node@192.168.24.150'}, {timeout, 4000} ]}
 
]}.
