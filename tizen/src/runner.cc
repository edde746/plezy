#include <flutter.h>

#include "generated_plugin_registrant.h"

// Standard flutter-tizen native embedding. Every Tizen plugin used by this
// target has a C++ or Dart implementation, so no .NET runtime is required.
class PlezyNGApp : public FlutterApp {
 public:
  bool OnCreate() override {
    if (FlutterApp::OnCreate()) {
      RegisterPlugins(this);
    }
    return IsRunning();
  }
};

int main(int argc, char* argv[]) {
  PlezyNGApp app;
  return app.Run(argc, argv);
}
