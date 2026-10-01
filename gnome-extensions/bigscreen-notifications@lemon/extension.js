import Clutter from 'gi://Clutter';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Layout from 'resource:///org/gnome/shell/ui/layout.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

const MARGIN = 16;

export default class BigscreenNotificationsExtension extends Extension {
    enable() {
        const tray = Main.messageTray;
        this._constraint = tray.get_constraints().find(c => c instanceof Layout.MonitorConstraint);

        tray.bannerAlignment = Clutter.ActorAlign.END;
        tray._bannerBin.y_align = Clutter.ActorAlign.END;
        tray._bannerBin.margin_right = MARGIN;
        tray._bannerBin.margin_bottom = MARGIN;

        // The shell slides banners between y = -height and 0; mirror it so they rise from the bottom edge.
        const ease = tray._bannerBin.ease;
        tray._bannerBin.ease = function (params) {
            if ('y' in params) {
                this.y = Math.abs(this.y);
                params = { ...params, y: Math.abs(params.y) };
            }
            return ease.call(this, params);
        };

        this._monitorsChangedId = Main.layoutManager.connect('monitors-changed', () => this._moveToLargestMonitor());
        this._moveToLargestMonitor();
    }

    disable() {
        Main.layoutManager.disconnect(this._monitorsChangedId);
        this._monitorsChangedId = null;

        const tray = Main.messageTray;
        tray.bannerAlignment = Clutter.ActorAlign.CENTER;
        tray._bannerBin.y_align = Clutter.ActorAlign.START;
        tray._bannerBin.margin_right = 0;
        tray._bannerBin.margin_bottom = 0;
        delete tray._bannerBin.ease;

        this._constraint.primary = true;
        this._constraint = null;
    }

    _moveToLargestMonitor() {
        const largest = Main.layoutManager.monitors.reduce((a, b) =>
            b.width * b.height > a.width * a.height ? b : a);
        this._constraint.index = largest.index;
    }
}
