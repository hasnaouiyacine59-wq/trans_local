from camoufox.sync_api import Camoufox

with Camoufox(headless=True) as browser:
    page = browser.new_page()
    page.goto("https://check.torproject.org/api/ip")
    print(page.inner_text("pre"))
