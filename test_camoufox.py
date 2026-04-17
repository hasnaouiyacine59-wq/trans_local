from camoufox.sync_api import Camoufox

with Camoufox(headless=True, proxy={"server": "socks5://127.0.0.1:9050"}) as browser:
    page = browser.new_page()
    page.goto("https://check.torproject.org/api/ip")
    print(page.content())
