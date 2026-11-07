import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Base directories
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAY_STORE_DIR = os.path.join(BASE_DIR, "assets", "play_store")

ICON_DIR = os.path.join(PLAY_STORE_DIR, "icon")
FEATURE_DIR = os.path.join(PLAY_STORE_DIR, "feature_graphic")
PHONE_DIR = os.path.join(PLAY_STORE_DIR, "screenshots", "phone")
TABLET_7_DIR = os.path.join(PLAY_STORE_DIR, "screenshots", "tablet_7inch")
TABLET_10_DIR = os.path.join(PLAY_STORE_DIR, "screenshots", "tablet_10inch")

for d in [ICON_DIR, FEATURE_DIR, PHONE_DIR, TABLET_7_DIR, TABLET_10_DIR]:
    os.makedirs(d, exist_ok=True)

# Font Loader
FONT_REGULAR = "C:/Windows/Fonts/segoeui.ttf"
FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_SEMIBOLD = "C:/Windows/Fonts/segoeuisl.ttf"

if not os.path.exists(FONT_REGULAR):
    FONT_REGULAR = "C:/Windows/Fonts/arial.ttf"
if not os.path.exists(FONT_BOLD):
    FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
if not os.path.exists(FONT_SEMIBOLD):
    FONT_SEMIBOLD = FONT_REGULAR

def get_font(size, bold=False):
    font_path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(font_path, int(size))
    except Exception:
        return ImageFont.load_default()

# Colors - Reading Room (Light) & Stacks at Night (Dark)
C_BLUE = (0, 75, 135)
C_ORANGE = (255, 107, 53)
C_DARK_BLUE = (0, 46, 82)
C_LIGHT_BG = (252, 248, 241)
C_LIGHT_CARD = (247, 242, 233)
C_LIGHT_CARD_HIGH = (236, 231, 220)
C_LIGHT_TEXT = (29, 27, 22)
C_LIGHT_MUTED = (74, 70, 63)
C_LIGHT_OUTLINE = (205, 200, 187)
C_PRIMARY_CONTAINER = (213, 227, 247)
C_SECONDARY_CONTAINER = (255, 220, 194)

C_DARK_BG = (21, 24, 31)
C_DARK_CARD = (33, 37, 45)
C_DARK_CARD_HIGH = (38, 43, 51)
C_DARK_TEXT = (228, 225, 217)
C_DARK_MUTED = (199, 197, 189)
C_DARK_PRIMARY = (163, 201, 240)
C_DARK_OUTLINE = (70, 72, 68)

def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    x0, y0, x1, y1 = bbox
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill, outline=outline, width=width)

# ==============================================================================
# 1. APP ICON GENERATOR (512x512)
# ==============================================================================
def generate_app_icon():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background rounded squircle / MD3 card shape
    margin = 16
    draw_rounded_rect(draw, [margin, margin, size - margin, size - margin], radius=110, fill=C_BLUE)

    # Inner subtle gradient circle highlight
    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(highlight)
    h_draw.ellipse([80, 40, size - 80, size - 120], fill=(255, 255, 255, 25))
    img = Image.alpha_composite(img, highlight)
    draw = ImageDraw.Draw(img)

    # Internet Archive Temple Facade (5 Columns)
    cx, cy = size // 2, 235

    # Pediment / Triangle Roof
    roof_points = [
        (cx, cy - 105),
        (cx - 170, cy - 35),
        (cx + 170, cy - 35)
    ]
    draw.polygon(roof_points, fill=(255, 255, 255))
    draw.rectangle([cx - 165, cy - 35, cx + 165, cy - 20], fill=(240, 240, 240))

    # Base steps
    draw.rectangle([cx - 175, cy + 115, cx + 175, cy + 130], fill=(255, 255, 255))
    draw.rectangle([cx - 185, cy + 130, cx + 185, cy + 145], fill=(240, 240, 240))

    # 5 Pillars
    col_width = 28
    col_spacing = 38
    start_x = cx - 2 * col_spacing - col_width // 2

    for i in range(5):
        px = start_x + i * col_spacing
        # Column capital
        draw.rectangle([px - 4, cy - 20, px + col_width + 4, cy - 10], fill=(255, 255, 255))
        # Shaft
        draw.rectangle([px, cy - 10, px + col_width, cy + 105], fill=(255, 255, 255))
        # Base
        draw.rectangle([px - 3, cy + 105, px + col_width + 3, cy + 115], fill=(240, 240, 240))

    # Modern Down-Arrow badge in Accent Orange
    badge_x, badge_y = cx + 80, cy + 60
    badge_r = 65
    draw.ellipse([badge_x - badge_r, badge_y - badge_r, badge_x + badge_r, badge_y + badge_r], fill=C_ORANGE)
    # Down arrow symbol
    arrow_w = 20
    draw.rectangle([badge_x - arrow_w//2, badge_y - 30, badge_x + arrow_w//2, badge_y + 10], fill=(255, 255, 255))
    arrow_head = [
        (badge_x - 35, badge_y + 5),
        (badge_x + 35, badge_y + 5),
        (badge_x, badge_y + 35)
    ]
    draw.polygon(arrow_head, fill=(255, 255, 255))

    icon_path = os.path.join(ICON_DIR, "icon_512x512.png")
    img.save(icon_path, "PNG")
    print("✓ App Icon generated:", icon_path)

# ==============================================================================
# 2. FEATURE GRAPHIC GENERATOR (1024x500)
# ==============================================================================
def generate_feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGBA", (w, h), C_DARK_BLUE)
    draw = ImageDraw.Draw(img)

    # Background pattern / gradient elements
    bg_gradient = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg_gradient)
    for x in range(w):
        r = int(0 + (x / w) * 20)
        g = int(75 - (x / w) * 25)
        b = int(135 - (x / w) * 40)
        bg_draw.line([(x, 0), (x, h)], fill=(r, g, b, 255))
    img = Image.alpha_composite(img, bg_gradient)
    draw = ImageDraw.Draw(img)

    # Decorative circles
    draw.ellipse([w - 450, -100, w + 150, 500], fill=(255, 255, 255, 10))
    draw.ellipse([w - 350, 50, w + 50, 450], fill=(255, 107, 53, 15))

    # App Icon on left
    icon_file = os.path.join(ICON_DIR, "icon_512x512.png")
    if os.path.exists(icon_file):
        app_icon = Image.open(icon_file).convert("RGBA")
        app_icon = app_icon.resize((210, 210), Image.Resampling.LANCZOS)
        img.paste(app_icon, (70, 145), app_icon)

    # Title & Tagline
    f_title = get_font(58, bold=True)
    f_tagline = get_font(28)
    f_bullet = get_font(22, bold=True)

    draw.text((315, 140), "IA Helper", font=f_title, fill=(255, 255, 255))
    draw.text((315, 215), "Your Internet Archive Companion", font=f_tagline, fill=C_DARK_PRIMARY)

    # Feature Bullet Chips
    bullets = [
        "📥 Smart Downloads",
        "🔍 35M+ Items Search",
        "📚 Offline Library",
        "⚡ Priority Queue"
    ]

    bx, by = 315, 280
    chip_h = 44
    for i, b_text in enumerate(bullets):
        row = i // 2
        col = i % 2
        cx = bx + col * 250
        cy = by + row * 56

        # Measure text using getbbox
        bbox = f_bullet.getbbox(b_text)
        tw = bbox[2] - bbox[0]
        cw = tw + 32

        draw_rounded_rect(draw, [cx, cy, cx + cw, cy + chip_h], radius=22, fill=(255, 255, 255, 30), outline=(255, 255, 255, 80), width=1)
        draw.text((cx + 16, cy + 9), b_text, font=f_bullet, fill=(255, 255, 255))

    # Preview Mockup Card on right side
    card_x, card_y = 820, 60
    card_w, card_h = 240, 420
    draw_rounded_rect(draw, [card_x, card_y, card_x + card_w, card_y + card_h], radius=24, fill=C_LIGHT_BG, outline=C_DARK_PRIMARY, width=2)

    # Simulated app top bar inside card
    draw_rounded_rect(draw, [card_x + 15, card_y + 35, card_x + card_w - 15, card_y + 75], radius=12, fill=C_LIGHT_CARD_HIGH)
    f_micro = get_font(12, bold=True)
    draw.text((card_x + 30, card_y + 48), "Search 35M+ archives...", font=f_micro, fill=C_LIGHT_MUTED)

    # Simulated items inside preview
    for k in range(3):
        iy = card_y + 95 + k * 80
        draw_rounded_rect(draw, [card_x + 15, iy, card_x + card_w - 15, iy + 68], radius=12, fill=C_LIGHT_CARD)
        draw_rounded_rect(draw, [card_x + 25, iy + 10, card_x + 70, iy + 58], radius=8, fill=C_PRIMARY_CONTAINER)
        draw.rectangle([card_x + 80, iy + 18, card_x + 190, iy + 28], fill=C_LIGHT_TEXT)
        draw.rectangle([card_x + 80, iy + 36, card_x + 150, iy + 44], fill=C_LIGHT_MUTED)

    feature_path = os.path.join(FEATURE_DIR, "feature_1024x500.png")
    img.save(feature_path, "PNG")
    print("✓ Feature Graphic generated:", feature_path)

# ==============================================================================
# 3. UI SCREENSHOT GENERATOR FRAMEWORK
# ==============================================================================
def draw_status_bar(draw, width, is_dark=False):
    fill_color = C_DARK_TEXT if is_dark else C_LIGHT_TEXT
    f_status = get_font(int(width * 0.022), bold=True)
    # Clock
    draw.text((int(width * 0.05), int(width * 0.02)), "9:41", font=f_status, fill=fill_color)
    # Icons text representation (WiFi, Battery)
    draw.text((int(width * 0.82), int(width * 0.02)), "5G  100%", font=f_status, fill=fill_color)

def draw_bottom_nav(draw, width, height, active_tab_index, is_dark=False):
    nav_h = int(height * 0.08)
    nav_top = height - nav_h
    bg_color = C_DARK_CARD if is_dark else C_LIGHT_CARD
    text_color = C_DARK_TEXT if is_dark else C_LIGHT_TEXT
    muted_color = C_DARK_MUTED if is_dark else C_LIGHT_MUTED
    active_bg = C_DARK_PRIMARY if is_dark else C_SECONDARY_CONTAINER

    draw.rectangle([0, nav_top, width, height], fill=bg_color)
    draw.line([(0, nav_top), (width, nav_top)], fill=C_DARK_OUTLINE if is_dark else C_LIGHT_OUTLINE, width=1)

    tabs = [
        ("Home", "🏠"),
        ("Library", "📚"),
        ("Discover", "🔍"),
        ("Transfers", "⚡"),
        ("Settings", "⚙️")
    ]

    tab_w = width / len(tabs)
    f_label = get_font(int(width * 0.022), bold=True)
    f_icon = get_font(int(width * 0.032))

    for i, (label, icon) in enumerate(tabs):
        tx = int(i * tab_w + tab_w / 2)
        ty = nav_top + int(nav_h * 0.3)

        if i == active_tab_index:
            # Active pill indicator
            pw, ph = int(tab_w * 0.65), int(nav_h * 0.45)
            draw_rounded_rect(draw, [tx - pw//2, ty - 8, tx + pw//2, ty + ph - 8], radius=ph//2, fill=active_bg)
            draw.text((tx - 12, ty - 4), icon, font=f_icon, fill=text_color)
            draw.text((tx - int(len(label)*3.5), ty + ph - 2), label, font=f_label, fill=text_color)
        else:
            draw.text((tx - 12, ty - 4), icon, font=f_icon, fill=muted_color)
            draw.text((tx - int(len(label)*3.5), ty + int(nav_h * 0.45) - 2), label, font=f_label, fill=muted_color)

def draw_nav_rail(draw, width, height, active_tab_index, is_dark=False):
    rail_w = int(width * 0.16)
    bg_color = C_DARK_CARD if is_dark else C_LIGHT_CARD
    text_color = C_DARK_TEXT if is_dark else C_LIGHT_TEXT
    muted_color = C_DARK_MUTED if is_dark else C_LIGHT_MUTED
    active_bg = C_DARK_PRIMARY if is_dark else C_SECONDARY_CONTAINER

    draw.rectangle([0, 0, rail_w, height], fill=bg_color)
    draw.line([(rail_w, 0), (rail_w, height)], fill=C_DARK_OUTLINE if is_dark else C_LIGHT_OUTLINE, width=1)

    # Logo at top of rail
    f_logo = get_font(int(rail_w * 0.22), bold=True)
    draw.text((int(rail_w * 0.2), int(height * 0.04)), "IA", font=f_logo, fill=C_ORANGE)

    tabs = [
        ("Home", "🏠"),
        ("Library", "📚"),
        ("Discover", "🔍"),
        ("Transfers", "⚡"),
        ("Settings", "⚙️")
    ]

    f_label = get_font(int(rail_w * 0.13), bold=True)
    f_icon = get_font(int(rail_w * 0.22))
    start_y = int(height * 0.15)
    spacing = int(height * 0.12)

    for i, (label, icon) in enumerate(tabs):
        cy = start_y + i * spacing
        cx = rail_w // 2

        if i == active_tab_index:
            pw, ph = int(rail_w * 0.75), int(rail_w * 0.5)
            draw_rounded_rect(draw, [cx - pw//2, cy - ph//2, cx + pw//2, cy + ph//2], radius=ph//2, fill=active_bg)
            draw.text((cx - 14, cy - ph//2 + 4), icon, font=f_icon, fill=text_color)
            draw.text((cx - int(len(label)*3.5), cy + ph//2 + 6), label, font=f_label, fill=text_color)
        else:
            draw.text((cx - 14, cy - 14), icon, font=f_icon, fill=muted_color)
            draw.text((cx - int(len(label)*3.5), cy + 18), label, font=f_label, fill=muted_color)

    return rail_w

def draw_header_banner(draw, width, headline, is_dark=False):
    banner_h = int(width * 0.14)
    bg_color = (0, 75, 135, 240) # Deep IA Blue overlay
    draw.rectangle([0, 0, width, banner_h], fill=bg_color)

    f_head = get_font(int(width * 0.038), bold=True)
    draw.text((int(width * 0.04), int(banner_h * 0.28)), headline, font=f_head, fill=(255, 255, 255))

# ==============================================================================
# SPECIFIC SCREEN BUILDERS
# ==============================================================================

def render_screen(surface_id, width, height, is_tablet=False):
    is_dark = (surface_id == "08_settings_dark")
    bg_color = C_DARK_BG if is_dark else C_LIGHT_BG
    card_color = C_DARK_CARD if is_dark else C_LIGHT_CARD
    card_high = C_DARK_CARD_HIGH if is_dark else C_LIGHT_CARD_HIGH
    text_color = C_DARK_TEXT if is_dark else C_LIGHT_TEXT
    muted_color = C_DARK_MUTED if is_dark else C_LIGHT_MUTED
    outline_color = C_DARK_OUTLINE if is_dark else C_LIGHT_OUTLINE
    primary_color = C_DARK_PRIMARY if is_dark else C_BLUE

    img = Image.new("RGBA", (width, height), bg_color)
    draw = ImageDraw.Draw(img)

    # Navigation layout setup
    tab_map = {
        "01_home": 0,
        "02_search_results": 2,
        "03_archive_detail": 0,
        "04_transfers": 3,
        "05_library": 1,
        "06_favorites": 1,
        "07_advanced_search": 2,
        "08_settings_dark": 4
    }
    active_tab = tab_map.get(surface_id, 0)

    # Banner Overlays
    banners = {
        "01_home": "Explore 35M+ Digital Items on Internet Archive",
        "02_search_results": "Search & Filter 35M+ Public Domain Archives",
        "03_archive_detail": "View Detailed Metadata, Files & Media Player",
        "04_transfers": "Manage High-Speed Downloads with Resume & Priority",
        "05_library": "Organize Saved Archives into Custom Collections",
        "06_favorites": "Instant Offline Access to Your Favorite Items",
        "07_advanced_search": "Precise Metadata Filtering by Media, Date & Type",
        "08_settings_dark": "Customizable App Preferences & Stacks Dark Mode"
    }
    draw_header_banner(draw, width, banners[surface_id], is_dark=is_dark)

    banner_h = int(width * 0.14)
    content_top = banner_h + int(height * 0.015)

    left_margin = 0
    if is_tablet:
        left_margin = draw_nav_rail(draw, width, height, active_tab, is_dark=is_dark)
    else:
        draw_bottom_nav(draw, width, height, active_tab, is_dark=is_dark)

    c_width = width - left_margin
    padding = int(c_width * 0.04)
    start_x = left_margin + padding

    # --------------------------------------------------------------------------
    # 01 HOME SURFACE
    # --------------------------------------------------------------------------
    if surface_id == "01_home":
        # Search Bar
        sb_y = content_top
        sb_h = int(height * 0.06)
        draw_rounded_rect(draw, [start_x, sb_y, width - padding, sb_y + sb_h], radius=sb_h//2, fill=card_high, outline=outline_color)
        f_search = get_font(int(c_width * 0.035))
        draw.text((start_x + int(sb_h * 0.4), sb_y + int(sb_h * 0.28)), "🔍  Search 35+ million books, audio, movies...", font=f_search, fill=muted_color)

        # Category Chips
        chips_y = sb_y + sb_h + int(height * 0.02)
        chip_h = int(height * 0.04)
        chips = ["📚 Books", "🎵 Audio", "🎬 Movies", "🕹️ Software", "🖼️ Images"]
        cx = start_x
        f_chip = get_font(int(c_width * 0.03), bold=True)
        for ch in chips:
            bbox = f_chip.getbbox(ch)
            cw = (bbox[2] - bbox[0]) + int(c_width * 0.05)
            if cx + cw < width - padding:
                draw_rounded_rect(draw, [cx, chips_y, cx + cw, chips_y + chip_h], radius=chip_h//2, fill=C_PRIMARY_CONTAINER, outline=None)
                draw.text((cx + int(c_width * 0.025), chips_y + int(chip_h * 0.2)), ch, font=f_chip, fill=C_BLUE)
                cx += cw + int(c_width * 0.025)

        # Featured Section Header
        sec_y = chips_y + chip_h + int(height * 0.025)
        f_sec = get_font(int(c_width * 0.045), bold=True)
        draw.text((start_x, sec_y), "Featured Archives & Collections", font=f_sec, fill=text_color)

        # Item List
        list_y = sec_y + int(height * 0.045)
        card_h = int(height * 0.11)
        items = [
            ("Prelinger Archives (1900s-1980s)", "60,000+ Educational & Industrial Films", "🎬 Video | 4.8★", C_ORANGE),
            ("Project Gutenberg Book Collection", "70,000+ Free Public Domain eBooks", "📚 Texts | 4.9★", C_BLUE),
            ("Old Time Radio Broadcasts", "100,000+ Classic Radio Shows & Dramas", "🎵 Audio | 4.7★", (0, 136, 204)),
            ("The Console Living Room", "Vintage Arcade & Console Software", "🕹️ Software | 4.9★", (46, 125, 50))
        ]

        for title, desc, meta, tag_color in items:
            if list_y + card_h > height - int(height * 0.1):
                break
            draw_rounded_rect(draw, [start_x, list_y, width - padding, list_y + card_h], radius=18, fill=card_color, outline=outline_color)
            # Icon Box
            ib_size = int(card_h * 0.75)
            draw_rounded_rect(draw, [start_x + int(card_h*0.12), list_y + int(card_h*0.12), start_x + int(card_h*0.12) + ib_size, list_y + int(card_h*0.12) + ib_size], radius=14, fill=tag_color)
            # Text
            f_title = get_font(int(c_width * 0.038), bold=True)
            f_desc = get_font(int(c_width * 0.028))
            f_meta = get_font(int(c_width * 0.026), bold=True)

            draw.text((start_x + ib_size + int(c_width*0.04), list_y + int(card_h*0.15)), title, font=f_title, fill=text_color)
            draw.text((start_x + ib_size + int(c_width*0.04), list_y + int(card_h*0.45)), desc, font=f_desc, fill=muted_color)
            draw.text((start_x + ib_size + int(c_width*0.04), list_y + int(card_h*0.72)), meta, font=f_meta, fill=primary_color)
            list_y += card_h + int(height * 0.015)

    # --------------------------------------------------------------------------
    # 02 SEARCH RESULTS SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "02_search_results":
        sb_y = content_top
        sb_h = int(height * 0.06)
        draw_rounded_rect(draw, [start_x, sb_y, width - padding, sb_y + sb_h], radius=sb_h//2, fill=card_high, outline=primary_color, width=2)
        f_search = get_font(int(c_width * 0.035), bold=True)
        draw.text((start_x + int(sb_h * 0.4), sb_y + int(sb_h * 0.28)), "classic old time radio", font=f_search, fill=text_color)

        # Filters Bar
        fbar_y = sb_y + sb_h + int(height * 0.015)
        f_filter = get_font(int(c_width * 0.028), bold=True)
        filters = ["✓ Audio Only", "📅 1930-1950", "⬇️ Most Downloaded", "⚙️ Filters"]
        fx = start_x
        for ft in filters:
            bbox = f_filter.getbbox(ft)
            fw = (bbox[2] - bbox[0]) + int(c_width * 0.04)
            draw_rounded_rect(draw, [fx, fbar_y, fx + fw, fbar_y + int(height * 0.035)], radius=14, fill=C_SECONDARY_CONTAINER if "✓" in ft else card_high)
            draw.text((fx + int(c_width * 0.02), fbar_y + int(height * 0.007)), ft, font=f_filter, fill=C_DARK_BLUE if "✓" in ft else text_color)
            fx += fw + int(c_width * 0.02)

        # Results Count
        cnt_y = fbar_y + int(height * 0.045)
        f_cnt = get_font(int(c_width * 0.032), bold=True)
        draw.text((start_x, cnt_y), "Found 142,850 Results", font=f_cnt, fill=muted_color)

        # Result Cards
        list_y = cnt_y + int(height * 0.035)
        card_h = int(height * 0.12)
        results = [
            ("The Shadow - Complete Radio Series (1937)", "Mutual Broadcasting System • 142 Episodes", "1.2 GB • 245,100 Downloads", "★ 4.9"),
            ("Mercury Theatre on the Air - Orson Welles", "CBS Radio Classic Dramas (1938)", "480 MB • 189,400 Downloads", "★ 5.0"),
            ("Dragnet Old Time Radio Collection", "NBC Radio Police Drama Series (1949)", "2.4 GB • 98,200 Downloads", "★ 4.8"),
            ("The Mysterious Traveler Science Fiction", "MBS Radio Mystery Broadcasts", "850 MB • 64,100 Downloads", "★ 4.7")
        ]

        for title, sub, size_dl, rating in results:
            if list_y + card_h > height - int(height * 0.1):
                break
            draw_rounded_rect(draw, [start_x, list_y, width - padding, list_y + card_h], radius=18, fill=card_color, outline=outline_color)
            f_rtitle = get_font(int(c_width * 0.036), bold=True)
            f_rsub = get_font(int(c_width * 0.028))
            f_rmeta = get_font(int(c_width * 0.026), bold=True)

            draw.text((start_x + int(c_width * 0.04), list_y + int(card_h * 0.15)), title, font=f_rtitle, fill=text_color)
            draw.text((start_x + int(c_width * 0.04), list_y + int(card_h * 0.45)), sub, font=f_rsub, fill=muted_color)
            draw.text((start_x + int(c_width * 0.04), list_y + int(card_h * 0.72)), size_dl, font=f_rmeta, fill=primary_color)
            draw.text((width - padding - int(c_width * 0.15), list_y + int(card_h * 0.15)), rating, font=f_rmeta, fill=C_ORANGE)

            list_y += card_h + int(height * 0.015)

    # --------------------------------------------------------------------------
    # 03 ARCHIVE DETAIL SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "03_archive_detail":
        # Header / Back bar
        h_y = content_top
        f_htitle = get_font(int(c_width * 0.045), bold=True)
        draw.text((start_x, h_y), "← Item Details", font=f_htitle, fill=text_color)

        # Hero Banner Card
        hero_y = h_y + int(height * 0.045)
        hero_h = int(height * 0.16)
        draw_rounded_rect(draw, [start_x, hero_y, width - padding, hero_y + hero_h], radius=20, fill=C_BLUE)

        f_hero_t = get_font(int(c_width * 0.048), bold=True)
        f_hero_sub = get_font(int(c_width * 0.032))
        draw.text((start_x + int(c_width * 0.05), hero_y + int(hero_h * 0.2)), "The War of the Worlds (1938)", font=f_hero_t, fill=(255, 255, 255))
        draw.text((start_x + int(c_width * 0.05), hero_y + int(hero_h * 0.55)), "Orson Welles & Mercury Theatre on the Air", font=f_hero_sub, fill=C_PRIMARY_CONTAINER)

        # File List Section
        sec_y = hero_y + hero_h + int(height * 0.025)
        f_sec = get_font(int(c_width * 0.038), bold=True)
        draw.text((start_x, sec_y), "Archive Files (3 files selected • 48.2 MB)", font=f_sec, fill=text_color)

        files_y = sec_y + int(height * 0.04)
        file_h = int(height * 0.075)
        files = [
            ("☑  war_of_the_worlds_original_broadcast.mp3", "Audio MP3 • 32.4 MB"),
            ("☑  mercury_theatre_script_1938.pdf", "Document PDF • 12.1 MB"),
            ("☑  broadcast_metadata_info.xml", "Metadata XML • 3.7 MB")
        ]

        for fname, fdesc in files:
            draw_rounded_rect(draw, [start_x, files_y, width - padding, files_y + file_h], radius=14, fill=card_color, outline=outline_color)
            f_fn = get_font(int(c_width * 0.03), bold=True)
            f_fd = get_font(int(c_width * 0.025))
            draw.text((start_x + int(c_width * 0.03), files_y + int(file_h * 0.2)), fname, font=f_fn, fill=text_color)
            draw.text((start_x + int(c_width * 0.03), files_y + int(file_h * 0.58)), fdesc, font=f_fd, fill=muted_color)
            files_y += file_h + int(height * 0.012)

        # Download Action Button
        btn_y = files_y + int(height * 0.02)
        btn_h = int(height * 0.065)
        draw_rounded_rect(draw, [start_x, btn_y, width - padding, btn_y + btn_h], radius=btn_h//2, fill=C_ORANGE)
        f_btn = get_font(int(c_width * 0.038), bold=True)
        draw.text((start_x + int(c_width * 0.22), btn_y + int(btn_h * 0.28)), "📥 Download Selected Files (48.2 MB)", font=f_btn, fill=(255, 255, 255))

    # --------------------------------------------------------------------------
    # 04 TRANSFERS SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "04_transfers":
        # Tabs Segmented Control
        tab_y = content_top
        tab_h = int(height * 0.05)
        draw_rounded_rect(draw, [start_x, tab_y, width - padding, tab_y + tab_h], radius=tab_h//2, fill=card_high)

        seg_w = (c_width - 2*padding) / 3
        draw_rounded_rect(draw, [start_x, tab_y, start_x + seg_w, tab_y + tab_h], radius=tab_h//2, fill=C_PRIMARY_CONTAINER)

        f_tab = get_font(int(c_width * 0.03), bold=True)
        draw.text((start_x + int(seg_w*0.18), tab_y + int(tab_h*0.25)), "Active (2)", font=f_tab, fill=C_BLUE)
        draw.text((start_x + seg_w + int(seg_w*0.18), tab_y + int(tab_h*0.25)), "Completed (14)", font=f_tab, fill=muted_color)
        draw.text((start_x + 2*seg_w + int(seg_w*0.18), tab_y + int(tab_h*0.25)), "Queue (5)", font=f_tab, fill=muted_color)

        # Download Progress Items
        list_y = tab_y + tab_h + int(height * 0.03)
        card_h = int(height * 0.15)

        # Active Download 1
        draw_rounded_rect(draw, [start_x, list_y, width - padding, list_y + card_h], radius=18, fill=card_color, outline=primary_color, width=2)
        f_t1 = get_font(int(c_width * 0.035), bold=True)
        f_t2 = get_font(int(c_width * 0.028))
        draw.text((start_x + int(c_width*0.04), list_y + int(card_h*0.12)), "war_of_the_worlds_original_broadcast.mp3", font=f_t1, fill=text_color)
        draw.text((start_x + int(c_width*0.04), list_y + int(card_h*0.35)), "64% • 31.0 MB of 48.2 MB (4.2 MB/s - 4s left)", font=f_t2, fill=primary_color)

        # Progress Bar
        pb_y = list_y + int(card_h * 0.62)
        pb_w = c_width - int(c_width * 0.08)
        draw_rounded_rect(draw, [start_x + int(c_width*0.04), pb_y, start_x + int(c_width*0.04) + pb_w, pb_y + 12], radius=6, fill=card_high)
        draw_rounded_rect(draw, [start_x + int(c_width*0.04), pb_y, start_x + int(c_width*0.04) + int(pb_w * 0.64), pb_y + 12], radius=6, fill=C_ORANGE)

        # Control Buttons
        draw.text((width - padding - int(c_width*0.18), list_y + int(card_h*0.75)), "⏸️ Pause  ✖️ Cancel", font=f_t2, fill=muted_color)

        # Active Download 2
        list_y += card_h + int(height * 0.02)
        draw_rounded_rect(draw, [start_x, list_y, width - padding, list_y + card_h], radius=18, fill=card_color, outline=outline_color)
        draw.text((start_x + int(c_width*0.04), list_y + int(card_h*0.12)), "gutenberg_books_archive_vol1.zip", font=f_t1, fill=text_color)
        draw.text((start_x + int(c_width*0.04), list_y + int(card_h*0.35)), "18% • 140.5 MB of 850 MB (6.8 MB/s - 1m 45s left)", font=f_t2, fill=primary_color)

        pb_y = list_y + int(card_h * 0.62)
        draw_rounded_rect(draw, [start_x + int(c_width*0.04), pb_y, start_x + int(c_width*0.04) + pb_w, pb_y + 12], radius=6, fill=card_high)
        draw_rounded_rect(draw, [start_x + int(c_width*0.04), pb_y, start_x + int(c_width*0.04) + int(pb_w * 0.18), pb_y + 12], radius=6, fill=C_BLUE)

        draw.text((width - padding - int(c_width*0.18), list_y + int(card_h*0.75)), "⏸️ Pause  ✖️ Cancel", font=f_t2, fill=muted_color)

    # --------------------------------------------------------------------------
    # 05 LIBRARY SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "05_library":
        # Segmented Control: Downloads | Collections | Favorites
        tab_y = content_top
        tab_h = int(height * 0.05)
        draw_rounded_rect(draw, [start_x, tab_y, width - padding, tab_y + tab_h], radius=tab_h//2, fill=card_high)

        seg_w = (c_width - 2*padding) / 3
        draw_rounded_rect(draw, [start_x + seg_w, tab_y, start_x + 2*seg_w, tab_y + tab_h], radius=tab_h//2, fill=C_PRIMARY_CONTAINER)

        f_tab = get_font(int(c_width * 0.03), bold=True)
        draw.text((start_x + int(seg_w*0.15), tab_y + int(tab_h*0.25)), "Downloads (14)", font=f_tab, fill=muted_color)
        draw.text((start_x + seg_w + int(seg_w*0.15), tab_y + int(tab_h*0.25)), "Collections (4)", font=f_tab, fill=C_BLUE)
        draw.text((start_x + 2*seg_w + int(seg_w*0.15), tab_y + int(tab_h*0.25)), "Favorites (8)", font=f_tab, fill=muted_color)

        # Storage Bar Card
        st_y = tab_y + tab_h + int(height * 0.02)
        st_h = int(height * 0.065)
        draw_rounded_rect(draw, [start_x, st_y, width - padding, st_y + st_h], radius=16, fill=card_color, outline=outline_color)
        f_st = get_font(int(c_width * 0.028), bold=True)
        draw.text((start_x + int(c_width*0.04), st_y + int(st_h*0.2)), "💾 Local Storage Used: 4.8 GB of 64.0 GB", font=f_st, fill=text_color)
        pb_y = st_y + int(st_h * 0.6)
        pb_w = c_width - int(c_width * 0.08)
        draw_rounded_rect(draw, [start_x + int(c_width*0.04), pb_y, start_x + int(c_width*0.04) + pb_w, pb_y + 8], radius=4, fill=card_high)
        draw_rounded_rect(draw, [start_x + int(c_width*0.04), pb_y, start_x + int(c_width*0.04) + int(pb_w * 0.15), pb_y + 8], radius=4, fill=C_ORANGE)

        # Grid / List of Collections
        grid_y = st_y + st_h + int(height * 0.025)
        col_card_h = int(height * 0.11)
        collections = [
            ("📁 Old Time Radio Master Archive", "24 Items • 1.8 GB", "Updated yesterday"),
            ("📁 Sci-Fi & Vintage Audiobooks", "12 Items • 940 MB", "Updated 3 days ago"),
            ("📁 Public Domain Software Vault", "8 Items • 1.4 GB", "Updated last week"),
            ("📁 Prelinger Historical Films", "6 Items • 680 MB", "Updated 2 weeks ago")
        ]

        for ctitle, ccount, cdate in collections:
            if grid_y + col_card_h > height - int(height * 0.1):
                break
            draw_rounded_rect(draw, [start_x, grid_y, width - padding, grid_y + col_card_h], radius=16, fill=card_color, outline=outline_color)
            f_ct = get_font(int(c_width * 0.035), bold=True)
            f_cd = get_font(int(c_width * 0.026))
            draw.text((start_x + int(c_width*0.04), grid_y + int(col_card_h*0.2)), ctitle, font=f_ct, fill=text_color)
            draw.text((start_x + int(c_width*0.04), grid_y + int(col_card_h*0.55)), ccount, font=f_cd, fill=primary_color)
            draw.text((width - padding - int(c_width*0.3), grid_y + int(col_card_h*0.55)), cdate, font=f_cd, fill=muted_color)
            grid_y += col_card_h + int(height * 0.015)

    # --------------------------------------------------------------------------
    # 06 FAVORITES SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "06_favorites":
        f_sec = get_font(int(c_width * 0.045), bold=True)
        draw.text((start_x, content_top), "❤️ Saved Favorites (8 Items)", font=f_sec, fill=text_color)

        list_y = content_top + int(height * 0.045)
        card_h = int(height * 0.11)
        favs = [
            ("Bram Stoker - Dracula (1897 Audio Edition)", "Public Domain Audiobook • 12 Tracks", "❤️ Saved"),
            ("NASA Apollo 11 Complete Mission Audio", "Historical Space Recordings • 4.2 GB", "❤️ Saved"),
            ("Console Living Room: Atari 2600 Library", "Classic Video Game ROM Archive", "❤️ Saved"),
            ("Internet Archive Book Images Collection", "Public Domain Historical Illustrations", "❤️ Saved")
        ]

        for ftitle, fdesc, fstatus in favs:
            if list_y + card_h > height - int(height * 0.1):
                break
            draw_rounded_rect(draw, [start_x, list_y, width - padding, list_y + card_h], radius=18, fill=card_color, outline=outline_color)
            f_ft = get_font(int(c_width * 0.035), bold=True)
            f_fd = get_font(int(c_width * 0.028))
            draw.text((start_x + int(c_width*0.04), list_y + int(card_h*0.2)), ftitle, font=f_ft, fill=text_color)
            draw.text((start_x + int(c_width*0.04), list_y + int(card_h*0.55)), fdesc, font=f_fd, fill=muted_color)
            draw.text((width - padding - int(c_width*0.22), list_y + int(card_h*0.35)), fstatus, font=f_ft, fill=C_ORANGE)
            list_y += card_h + int(height * 0.015)

    # --------------------------------------------------------------------------
    # 07 ADVANCED SEARCH SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "07_advanced_search":
        f_sec = get_font(int(c_width * 0.045), bold=True)
        draw.text((start_x, content_top), "⚙️ Advanced Search Filters", font=f_sec, fill=text_color)

        fy = content_top + int(height * 0.045)
        f_lbl = get_font(int(c_width * 0.032), bold=True)
        f_opt = get_font(int(c_width * 0.028))

        # Media Type Section
        draw.text((start_x, fy), "Media Type Filters", font=f_lbl, fill=primary_color)
        fy += int(height * 0.03)
        mtypes = ["☑ Audio", "☑ Texts", "☐ Movies & Video", "☐ Software"]
        for mt in mtypes:
            draw_rounded_rect(draw, [start_x, fy, start_x + int(c_width*0.42), fy + int(height*0.045)], radius=12, fill=card_color, outline=outline_color)
            draw.text((start_x + 12, fy + int(height*0.01)), mt, font=f_opt, fill=text_color)
            fy += int(height * 0.052)

        # Date Range Section
        fy += int(height * 0.01)
        draw.text((start_x, fy), "Year Range: 1920 - 1960", font=f_lbl, fill=primary_color)
        fy += int(height * 0.03)
        draw_rounded_rect(draw, [start_x, fy, width - padding, fy + 12], radius=6, fill=card_high)
        draw_rounded_rect(draw, [start_x + int(c_width*0.2), fy, start_x + int(c_width*0.7), fy + 12], radius=6, fill=C_ORANGE)
        fy += int(height * 0.035)

        # Apply Filters Button
        btn_h = int(height * 0.06)
        draw_rounded_rect(draw, [start_x, fy, width - padding, fy + btn_h], radius=btn_h//2, fill=C_BLUE)
        f_abtn = get_font(int(c_width * 0.038), bold=True)
        draw.text((start_x + int(c_width * 0.25), fy + int(btn_h * 0.25)), "🔍 Apply Filters (142,850 Results)", font=f_abtn, fill=(255, 255, 255))

    # --------------------------------------------------------------------------
    # 08 SETTINGS (DARK MODE) SURFACE
    # --------------------------------------------------------------------------
    elif surface_id == "08_settings_dark":
        f_sec = get_font(int(c_width * 0.045), bold=True)
        draw.text((start_x, content_top), "⚙️ App Preferences", font=f_sec, fill=text_color)

        sy = content_top + int(height * 0.045)
        f_grp = get_font(int(c_width * 0.032), bold=True)
        f_stitle = get_font(int(c_width * 0.032), bold=True)
        f_ssub = get_font(int(c_width * 0.026))

        settings_list = [
            ("🌙 Appearance & Theme", [
                ("Dark Mode Theme", "Stacks at Night (Deep Ink Blue)", "ON [🔘]"),
                ("Dynamic Color Accent", "Material 3 Expressive Tones", "ON [🔘]")
            ]),
            ("⚡ Network & Bandwidth", [
                ("Download Over Wi-Fi Only", "Pause queue on cellular connection", "ON [🔘]"),
                ("Concurrent Downloads", "Maximum 3 parallel file streams", "3 Streams")
            ]),
            ("💾 Storage & Downloads", [
                ("Download Location", "/storage/emulated/0/Download/IA-Helper", "Change")
            ])
        ]

        for grp_title, options in settings_list:
            if sy > height - int(height * 0.12):
                break
            draw.text((start_x, sy), grp_title, font=f_grp, fill=C_DARK_PRIMARY)
            sy += int(height * 0.035)

            for opt_title, opt_sub, opt_val in options:
                opt_h = int(height * 0.08)
                draw_rounded_rect(draw, [start_x, sy, width - padding, sy + opt_h], radius=16, fill=card_color, outline=outline_color)
                draw.text((start_x + int(c_width*0.04), sy + int(opt_h*0.18)), opt_title, font=f_stitle, fill=text_color)
                draw.text((start_x + int(c_width*0.04), sy + int(opt_h*0.55)), opt_sub, font=f_ssub, fill=muted_color)
                draw.text((width - padding - int(c_width*0.22), sy + int(opt_h*0.35)), opt_val, font=f_stitle, fill=C_DARK_PRIMARY)
                sy += opt_h + int(height * 0.012)
            sy += int(height * 0.015)

    return img

# ==============================================================================
# 4. GENERATE ALL 26 REQUIRED IMAGES
# ==============================================================================
def generate_all_assets():
    print("Beginning generation of Play Store graphics & screenshots...")

    # 1. App Icon
    generate_app_icon()

    # 2. Feature Graphic
    generate_feature_graphic()

    # 3. Phone Screenshots (8 surfaces: 1080x1920)
    surfaces = [
        "01_home",
        "02_search_results",
        "03_archive_detail",
        "04_transfers",
        "05_library",
        "06_favorites",
        "07_advanced_search",
        "08_settings_dark"
    ]

    print("\n--- Generating 8 Phone Screenshots (1080x1920) ---")
    for s_id in surfaces:
        phone_img = render_screen(s_id, 1080, 1920, is_tablet=False)
        out_p = os.path.join(PHONE_DIR, f"{s_id}.png")
        phone_img.save(out_p, "PNG")
        print("✓ Phone Screenshot:", out_p)

    # 4. 7-Inch Tablet Screenshots (8 surfaces: 1200x1920)
    print("\n--- Generating 8 7-Inch Tablet Screenshots (1200x1920) ---")
    for s_id in surfaces:
        t7_img = render_screen(s_id, 1200, 1920, is_tablet=True)
        out_p = os.path.join(TABLET_7_DIR, f"{s_id}.png")
        t7_img.save(out_p, "PNG")
        print("✓ 7-Inch Tablet Screenshot:", out_p)

    # 5. 10-Inch Tablet Screenshots (8 surfaces: 1600x2560)
    print("\n--- Generating 8 10-Inch Tablet Screenshots (1600x2560) ---")
    for s_id in surfaces:
        t10_img = render_screen(s_id, 1600, 2560, is_tablet=True)
        out_p = os.path.join(TABLET_10_DIR, f"{s_id}.png")
        t10_img.save(out_p, "PNG")
        print("✓ 10-Inch Tablet Screenshot:", out_p)

    print("\n========================================================")
    print("🎉 ALL PLAY STORE VISUAL ASSETS GENERATED SUCCESSFULLY!")
    print("========================================================")

if __name__ == "__main__":
    generate_all_assets()
