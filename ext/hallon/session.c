#include "common.h"
#include "session.h"

static VALUE cSession_alloc(VALUE klass)
{
  return Data_Make_Ptr(klass, sp_session, NULL, cSession_free);
}

static void cSession_free(sp_session **session_ptr)
{
  ASSERT_NOT_EMPTY(session_ptr);
  sp_session_release(*session_ptr);
}

/*
  Document-method: initialize(appkey, user_agent = "Hallon", settings_path = Dir.mktmpdir "se.burgestrand.hallon", cache_path = settings_path)
  
  @param [String] appkey Your libspotify application key (binary).
  @param [String] user_agent (default: Hallon)
  @param [String] settings_path (default uses mkdtmp: /tmp/se.burgestrand.hallon.XXXXXX)
  @param [String] cache_path (default uses settings_path)
*/
static VALUE cSession_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE appkey, user_agent, settings_path, cache_path;
  VALUE tmp_prefix = rb_str_new2("se.burgestrand.hallon");
  VALUE tmpdir = rb_funcall3(rb_cDir, rb_intern("mktmpdir"), 1, &tmp_prefix);
  
  switch (rb_scan_args(argc, argv, "13", &appkey, &user_agent, &settings_path, &cache_path))
  {
    case 1: user_agent    = rb_str_new2("Hallon");
    case 2: settings_path = tmpdir;
    case 3: cache_path    = settings_path;
  }
  
  Check_Type(appkey, T_STRING);
  Check_Type(user_agent, T_STRING);
  Check_Type(settings_path, T_STRING);
  Check_Type(cache_path, T_STRING);
  
  sp_session_callbacks callbacks =
  {
    .logged_in              = NULL,
    .logged_out             = NULL,
    .metadata_updated       = NULL,
    .connection_error       = NULL,
    .message_to_user        = NULL,
    .play_token_lost        = NULL,
    .streaming_error        = NULL,
    .log_message            = NULL,
    .userinfo_updated       = NULL,
    .notify_main_thread     = NULL,
    .music_delivery         = NULL,
    .end_of_track           = NULL,
    .start_playback         = NULL,
    .stop_playback          = NULL,
    .get_audio_buffer_stats = NULL
  };
  
  sp_session_config config =
  {
    .api_version          = SPOTIFY_API_VERSION,
    .cache_location       = StringValuePtr(cache_path),
    .settings_location    = StringValuePtr(settings_path),
    .application_key      = RSTRING_PTR(appkey),
    .application_key_size = RSTRING_LEN(appkey),
    .user_agent           = StringValuePtr(user_agent),
    .callbacks            = &callbacks,
    .userdata             = (void *) self,
    .tiny_settings        = true,
  };
  
  sp_session **session_ptr = Data_Get_Ptr(self, sp_session);
  sp_error error = sp_session_create(&config, &(*session_ptr));
  
  ASSERT_OK(error);
  
  return self;
}

VALUE cSession_state(VALUE self)
{
  sp_session *session_ptr = Data_Get_PVal(self, sp_session);
  
  switch(sp_session_connectionstate(session_ptr))
  {
    case SP_CONNECTION_STATE_LOGGED_OUT: return STR2SYM("logged_out");
    case SP_CONNECTION_STATE_LOGGED_IN: return STR2SYM("logged_in");
    case SP_CONNECTION_STATE_DISCONNECTED: return STR2SYM("disconnected");
    default: return STR2SYM("undefined");
  }
}

void Init_Session(VALUE mHallon)
{
  rb_require("tmpdir");
  
  VALUE cSession = rb_define_class_under(mHallon, "Session", rb_cObject);
  rb_define_alloc_func(cSession, cSession_alloc);
  rb_define_method(cSession, "initialize", cSession_initialize, -1);
  rb_define_method(cSession, "state", cSession_state, 0);
}