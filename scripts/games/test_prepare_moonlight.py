import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location('prepare', Path(__file__).with_name('prepare_moonlight.py'))
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class EmbeddedManifestTests(unittest.TestCase):
    def test_source_manifest_cannot_export_components_or_replace_host_policy(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'original.xml'
            target = Path(directory) / 'embedded.xml'
            source.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
              <uses-permission android:name="com.android.providers.tv.permission.WRITE_EPG_DATA"/>
              <application android:allowBackup="true" android:networkSecurityConfig="@xml/other">
                <activity android:name=".Game" android:exported="true" android:launchMode="singleTask" android:theme="@style/StreamTheme">
                  <intent-filter><action android:name="android.intent.action.MAIN"/></intent-filter>
                </activity>
                <service android:name=".discovery.DiscoveryService" android:exported="true"/>
                <provider android:name=".PosterContentProvider" android:exported="true"/>
              </application></manifest>''')
            prepare.private_manifest(source, target)
            root = ET.parse(target).getroot()
            app = root.find('application')
            self.assertEqual(app.attrib, {})
            self.assertEqual(root.findall('uses-permission'), [])
            self.assertEqual(app.findall('provider'), [])
            self.assertEqual(app.findall('.//intent-filter'), [])
            for component in app:
                self.assertEqual(component.get(prepare.ANDROID + 'exported'), 'false')
                self.assertTrue(component.get(prepare.ANDROID + 'name').startswith('com.limelight.'))
                self.assertNotIn(prepare.ANDROID + 'launchMode', component.attrib)
            self.assertEqual(app.find('activity').get(prepare.ANDROID + 'theme'), '@style/StreamTheme')

    def test_cancel_patch_is_bounded_and_fails_closed_if_upstream_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'NvHTTP.java'
            path.write_text('public class NvHTTP {\n.readTimeout(0, TimeUnit.MILLISECONDS)\n}')
            prepare.patch_http(path)
            self.assertIn('callTimeout(90, TimeUnit.SECONDS)', path.read_text())
            self.assertEqual(path.read_text().count('dispatcher().cancelAll()'), 3)
            path.write_text('public class Different {}')
            with self.assertRaises(ValueError):
                prepare.patch_http(path)


if __name__ == '__main__':
    unittest.main()
