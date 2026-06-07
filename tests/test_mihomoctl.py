#!/usr/bin/env python3
"""Unit tests for mihomoctl."""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch, mock_open

# Add parent dir to path so we can import mihomoctl
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import mihomoctl


class TestExitCodes(unittest.TestCase):
    """Test exit code constants."""

    def test_exit_codes_exist(self):
        self.assertEqual(mihomoctl.EXIT_OK, 0)
        self.assertEqual(mihomoctl.EXIT_GENERAL, 1)
        self.assertEqual(mihomoctl.EXIT_NOT_FOUND, 2)
        self.assertEqual(mihomoctl.EXIT_API_DOWN, 3)
        self.assertEqual(mihomoctl.EXIT_AUTH_FAILED, 4)
        self.assertEqual(mihomoctl.EXIT_INVALID_INPUT, 5)
        self.assertEqual(mihomoctl.EXIT_DEPENDENCY, 6)

    def test_die_raises_system_exit(self):
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.die("test error")
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_GENERAL)

    def test_die_with_custom_code(self):
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.die("not found", mihomoctl.EXIT_NOT_FOUND)
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_NOT_FOUND)

    def test_need_root_raises_when_not_root(self):
        with patch("mihomoctl.os.geteuid", return_value=1000):
            with self.assertRaises(SystemExit) as ctx:
                mihomoctl.need_root("test action")
            self.assertEqual(ctx.exception.code, mihomoctl.EXIT_DEPENDENCY)


class TestStateManagement(unittest.TestCase):
    """Test read_state and write_state."""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.original_state = mihomoctl.STATE
        mihomoctl.STATE = Path(self.test_dir) / "state.json"

    def tearDown(self):
        mihomoctl.STATE = self.original_state
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_read_state_returns_defaults_when_no_file(self):
        state = mihomoctl.read_state()
        self.assertEqual(state["mode"], "tun")
        self.assertIsNone(state["group"])
        self.assertIsNone(state["node"])
        self.assertIsNone(state["profile"])

    def test_write_state_creates_file(self):
        state = {"mode": "proxy", "group": "PROXY", "node": "HK-01", "profile": None}
        mihomoctl.write_state(state)
        self.assertTrue(mihomoctl.STATE.exists())

    def test_write_then_read_roundtrip(self):
        state = {"mode": "proxy", "group": "PROXY", "node": "HK-01", "profile": "YouTube"}
        mihomoctl.write_state(state)
        loaded = mihomoctl.read_state()
        self.assertEqual(loaded["mode"], "proxy")
        self.assertEqual(loaded["group"], "PROXY")
        self.assertEqual(loaded["node"], "HK-01")
        self.assertEqual(loaded["profile"], "YouTube")

    def test_read_state_returns_defaults_on_corrupt_file(self):
        mihomoctl.STATE.write_text("not valid json {{{")
        state = mihomoctl.read_state()
        self.assertEqual(state["mode"], "tun")
        self.assertIsNone(state["group"])

    def test_write_state_with_dns_overrides(self):
        state = {
            "mode": "tun",
            "group": "PROXY",
            "node": "HK-01",
            "profile": None,
            "dns": {
                "enhanced-mode": "fake-ip",
                "nameservers": ["https://dns.google/dns-query"],
                "fallback": ["https://1.1.1.1/dns-query"]
            }
        }
        mihomoctl.write_state(state)
        loaded = mihomoctl.read_state()
        self.assertEqual(loaded["dns"]["enhanced-mode"], "fake-ip")
        self.assertEqual(len(loaded["dns"]["nameservers"]), 1)
        self.assertEqual(loaded["dns"]["nameservers"][0], "https://dns.google/dns-query")


class TestYamlHelpers(unittest.TestCase):
    """Test load_yaml and save_yaml."""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_load_yaml_reads_valid_file(self):
        path = Path(self.test_dir) / "test.yaml"
        path.write_text("key: value\nlist:\n  - a\n  - b\n")
        data = mihomoctl.load_yaml(path)
        self.assertEqual(data["key"], "value")
        self.assertEqual(data["list"], ["a", "b"])

    def test_load_yaml_raises_on_missing_file(self):
        path = Path(self.test_dir) / "nonexistent.yaml"
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.load_yaml(path)
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_NOT_FOUND)

    def test_load_yaml_raises_on_non_dict(self):
        path = Path(self.test_dir) / "list.yaml"
        path.write_text("- item1\n- item2\n")
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.load_yaml(path)
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_INVALID_INPUT)

    def test_save_yaml_creates_file(self):
        path = Path(self.test_dir) / "out.yaml"
        data = {"proxies": [{"name": "test"}], "mode": "rule"}
        mihomoctl.save_yaml(path, data)
        self.assertTrue(path.exists())
        loaded = mihomoctl.load_yaml(path)
        self.assertEqual(loaded["mode"], "rule")

    def test_save_yaml_preserves_unicode(self):
        path = Path(self.test_dir) / "unicode.yaml"
        data = {"name": "Тестовая нода"}
        mihomoctl.save_yaml(path, data)
        loaded = mihomoctl.load_yaml(path)
        self.assertEqual(loaded["name"], "Тестовая нода")


class TestProxyHelpers(unittest.TestCase):
    """Test is_group, is_selector, is_node_name, candidate_groups."""

    def test_is_group_true(self):
        obj = {"type": "Selector", "all": ["node1", "node2"], "now": "node1"}
        self.assertTrue(mihomoctl.is_group(obj))

    def test_is_group_false_when_no_all(self):
        obj = {"type": "Selector", "name": "test"}
        self.assertFalse(mihomoctl.is_group(obj))

    def test_is_group_false_when_not_dict(self):
        self.assertFalse(mihomoctl.is_group("string"))
        self.assertFalse(mihomoctl.is_group(None))
        self.assertFalse(mihomoctl.is_group(42))

    def test_is_selector_true(self):
        obj = {"type": "Selector", "all": ["node1"], "now": "node1"}
        self.assertTrue(mihomoctl.is_selector(obj))

    def test_is_selector_false_for_urltest(self):
        obj = {"type": "URLTest", "all": ["node1"], "now": "node1"}
        self.assertFalse(mihomoctl.is_selector(obj))

    def test_is_selector_false_for_fallback(self):
        obj = {"type": "Fallback", "all": ["node1"], "now": "node1"}
        self.assertFalse(mihomoctl.is_selector(obj))

    def test_is_node_name_true_for_regular_node(self):
        proxies = {"HK-01": {"type": "ss", "all": []}}
        self.assertTrue(mihomoctl.is_node_name("HK-01", proxies))

    def test_is_node_name_false_for_direct(self):
        self.assertFalse(mihomoctl.is_node_name("DIRECT", {}))

    def test_is_node_name_false_for_reject(self):
        self.assertFalse(mihomoctl.is_node_name("REJECT", {}))

    def test_is_node_name_false_for_group(self):
        proxies = {
            "PROXY": {"type": "Selector", "all": ["HK-01"], "now": "HK-01"}
        }
        self.assertFalse(mihomoctl.is_node_name("PROXY", proxies))

    def test_is_node_name_false_for_direct_type(self):
        proxies = {"direct": {"type": "Direct", "all": []}}
        self.assertFalse(mihomoctl.is_node_name("direct", proxies))

    def test_candidate_groups(self):
        proxies = {
            "PROXY": {"type": "Selector", "all": ["HK-01", "JP-01"], "now": "HK-01"},
            "AUTO": {"type": "URLTest", "all": ["HK-01", "JP-01"], "now": "JP-01"},
            "DIRECT": {"type": "Direct", "all": []},
        }
        groups = mihomoctl.candidate_groups(proxies)
        # Only PROXY is a selector
        self.assertEqual(len(groups), 1)
        self.assertEqual(groups[0][0], "PROXY")
        self.assertEqual(groups[0][2], ["HK-01", "JP-01"])

    def test_candidate_groups_filters_non_nodes(self):
        proxies = {
            "PROXY": {"type": "Selector", "all": ["HK-01", "DIRECT"], "now": "HK-01"},
        }
        groups = mihomoctl.candidate_groups(proxies)
        self.assertEqual(len(groups), 1)
        # DIRECT should be filtered out
        self.assertEqual(groups[0][2], ["HK-01"])

    def test_get_group_nodes(self):
        proxies = {
            "PROXY": {"type": "Selector", "all": ["HK-01", "JP-01", "DIRECT"], "now": "HK-01"},
        }
        nodes = mihomoctl.get_group_nodes("PROXY", proxies)
        self.assertEqual(nodes, ["HK-01", "JP-01"])

    def test_get_group_nodes_raises_on_nonexistent_group(self):
        proxies = {}
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.get_group_nodes("NONEXISTENT", proxies)
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_NOT_FOUND)

    def test_get_group_nodes_raises_when_no_nodes(self):
        proxies = {
            "EMPTY": {"type": "Selector", "all": ["DIRECT", "REJECT"], "now": "DIRECT"},
        }
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.get_group_nodes("EMPTY", proxies)
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_NOT_FOUND)


class TestValidateSubUrl(unittest.TestCase):
    """Test validate_sub_url function."""

    @patch("mihomoctl.urllib.request.urlopen")
    def test_valid_url_returns_ok(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        ok, msg = mihomoctl.validate_sub_url("https://example.com/sub")
        self.assertTrue(ok)
        self.assertIn("200", msg)

    @patch("mihomoctl.urllib.request.urlopen")
    def test_404_returns_not_ok(self, mock_urlopen):
        import urllib.error
        mock_urlopen.side_effect = urllib.error.HTTPError(
            "https://example.com", 404, "Not Found", {}, None
        )
        ok, msg = mihomoctl.validate_sub_url("https://example.com/sub")
        self.assertFalse(ok)
        self.assertIn("404", msg)

    @patch("mihomoctl.urllib.request.urlopen")
    def test_401_returns_ok_with_auth_message(self, mock_urlopen):
        import urllib.error
        mock_urlopen.side_effect = urllib.error.HTTPError(
            "https://example.com", 401, "Unauthorized", {}, None
        )
        ok, msg = mihomoctl.validate_sub_url("https://example.com/sub")
        self.assertTrue(ok)
        self.assertIn("auth required", msg)

    @patch("mihomoctl.urllib.request.urlopen")
    def test_network_error_returns_not_ok(self, mock_urlopen):
        mock_urlopen.side_effect = ConnectionError("Network unreachable")
        ok, msg = mihomoctl.validate_sub_url("https://example.com/sub")
        self.assertFalse(ok)
        self.assertIn("Network unreachable", msg)


class TestFzfSelect(unittest.TestCase):
    """Test fzf_select helper."""

    @patch("mihomoctl.shutil.which")
    def test_returns_none_when_fzf_cancelled(self, mock_which):
        mock_which.return_value = "/usr/bin/fzf"
        with patch("mihomoctl.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(stdout="")
            result = mihomoctl.fzf_select(["a", "b", "c"], "test> ")
            self.assertIsNone(result)

    @patch("mihomoctl.shutil.which")
    def test_returns_selected_item(self, mock_which):
        mock_which.return_value = "/usr/bin/fzf"
        with patch("mihomoctl.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(stdout="b\n")
            result = mihomoctl.fzf_select(["a", "b", "c"], "test> ")
            self.assertEqual(result, "b")

    @patch("mihomoctl.shutil.which")
    def test_fallback_numbered_list(self, mock_which):
        mock_which.return_value = None  # fzf not installed
        with patch("builtins.input", return_value="2"):
            with patch("builtins.print"):
                result = mihomoctl.fzf_select(["a", "b", "c"], "test> ")
                self.assertEqual(result, "b")


class TestGetProxies(unittest.TestCase):
    """Test get_proxies function."""

    @patch("mihomoctl.wait_api")
    @patch("mihomoctl.http_json")
    def test_returns_proxies_dict(self, mock_http, mock_wait):
        mock_http.return_value = {
            "proxies": {
                "PROXY": {"type": "Selector", "all": ["HK-01"], "now": "HK-01"}
            }
        }
        proxies = mihomoctl.get_proxies()
        self.assertIn("PROXY", proxies)

    @patch("mihomoctl.wait_api")
    @patch("mihomoctl.http_json")
    def test_raises_on_bad_response(self, mock_http, mock_wait):
        mock_http.return_value = {"not_proxies": {}}
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.get_proxies()
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_API_DOWN)


class TestWaitApi(unittest.TestCase):
    """Test wait_api function."""

    @patch("mihomoctl.http_json")
    def test_returns_on_success(self, mock_http):
        mock_http.return_value = {"version": "v1.19.27"}
        result = mihomoctl.wait_api(timeout=1)
        self.assertEqual(result["version"], "v1.19.27")

    @patch("mihomoctl.http_json")
    def test_raises_on_timeout(self, mock_http):
        mock_http.side_effect = ConnectionError("refused")
        with self.assertRaises(SystemExit) as ctx:
            mihomoctl.wait_api(timeout=0.1)
        self.assertEqual(ctx.exception.code, mihomoctl.EXIT_API_DOWN)


class TestGenerateConfig(unittest.TestCase):
    """Test generate_config function with mocked dependencies."""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.original_etc = mihomoctl.ETC
        self.original_var = mihomoctl.VAR
        self.original_state = mihomoctl.STATE
        self.original_base = mihomoctl.BASE_CFG
        self.original_cfg = mihomoctl.CFG

        mihomoctl.ETC = Path(self.test_dir) / "etc"
        mihomoctl.VAR = Path(self.test_dir) / "var"
        mihomoctl.STATE = mihomoctl.VAR / "state.json"
        mihomoctl.BASE_CFG = mihomoctl.ETC / "base.yaml"
        mihomoctl.CFG = mihomoctl.ETC / "config.yaml"

        mihomoctl.ETC.mkdir(parents=True, exist_ok=True)
        mihomoctl.VAR.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        mihomoctl.ETC = self.original_etc
        mihomoctl.VAR = self.original_var
        mihomoctl.STATE = self.original_state
        mihomoctl.BASE_CFG = self.original_base
        mihomoctl.CFG = self.original_cfg
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def _create_base_yaml(self, data=None):
        if data is None:
            data = {"proxies": [], "proxy-groups": [], "rules": []}
        mihomoctl.save_yaml(mihomoctl.BASE_CFG, data)

    def _create_state(self, data=None):
        if data is None:
            data = {"mode": "tun", "group": "PROXY", "node": "HK-01", "profile": None}
        mihomoctl.write_state(data)

    @patch("mihomoctl.subprocess.run")
    @patch("mihomoctl.os.geteuid", return_value=0)
    def test_generate_config_tun_mode(self, mock_euid, mock_run):
        self._create_base_yaml()
        self._create_state({"mode": "tun", "group": None, "node": None, "profile": None})
        mock_run.return_value = MagicMock(returncode=0)

        mihomoctl.generate_config()

        self.assertTrue(mihomoctl.CFG.exists())
        cfg = mihomoctl.load_yaml(mihomoctl.CFG)
        self.assertEqual(cfg["mode"], "rule")
        self.assertTrue(cfg["tun"]["enable"])
        self.assertIn("dns-hijack", cfg["tun"])

    @patch("mihomoctl.subprocess.run")
    @patch("mihomoctl.os.geteuid", return_value=0)
    def test_generate_config_proxy_mode(self, mock_euid, mock_run):
        self._create_base_yaml()
        self._create_state({"mode": "proxy", "group": None, "node": None, "profile": None})
        mock_run.return_value = MagicMock(returncode=0)

        mihomoctl.generate_config()

        cfg = mihomoctl.load_yaml(mihomoctl.CFG)
        self.assertFalse(cfg["tun"]["enable"])
        self.assertNotIn("dns-hijack", cfg["tun"])

    @patch("mihomoctl.subprocess.run")
    @patch("mihomoctl.os.geteuid", return_value=0)
    def test_generate_config_applies_dns_overrides(self, mock_euid, mock_run):
        self._create_base_yaml()
        self._create_state({
            "mode": "tun",
            "group": None,
            "node": None,
            "profile": None,
            "dns": {
                "enhanced-mode": "fake-ip",
                "nameservers": ["https://dns.google/dns-query"],
                "fallback": ["https://dns.quad9.net/dns-query"]
            }
        })
        mock_run.return_value = MagicMock(returncode=0)

        mihomoctl.generate_config()

        cfg = mihomoctl.load_yaml(mihomoctl.CFG)
        self.assertEqual(cfg["dns"]["enhanced-mode"], "fake-ip")
        self.assertEqual(cfg["dns"]["nameserver"], ["https://dns.google/dns-query"])
        self.assertEqual(cfg["dns"]["fallback"], ["https://dns.quad9.net/dns-query"])

    @patch("mihomoctl.subprocess.run")
    @patch("mihomoctl.os.geteuid", return_value=0)
    def test_generate_config_removes_fake_ip_in_redir_host(self, mock_euid, mock_run):
        self._create_base_yaml({"dns": {"fake-ip-range": "198.18.0.0/16"}})
        self._create_state({"mode": "tun", "group": None, "node": None, "profile": None})
        mock_run.return_value = MagicMock(returncode=0)

        mihomoctl.generate_config()

        cfg = mihomoctl.load_yaml(mihomoctl.CFG)
        self.assertNotIn("fake-ip-range", cfg["dns"])
        self.assertNotIn("fake-ip-filter", cfg["dns"])


if __name__ == "__main__":
    unittest.main()
