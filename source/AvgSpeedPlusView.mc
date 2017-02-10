using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

const EQUAL = 1;
const SLOWER = 2;
const FASTER = 4;
const UNKNOWN = 8;
const PAUSED = 16;

class AvgSpeedPlusView extends Ui.DataField {

    hidden var mSpeed;
    hidden var mStatus;
    hidden var mFormatString = "%.1f";
    hidden var mUnit1String;
    hidden var mUnit2String;

    function initialize() {
        DataField.initialize();
        mSpeed = 0.0f;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 16;
        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY + 7;

        View.findDrawableById("label").setText(Rez.Strings.label);

        var unit1 = View.findDrawableById("unit1");
        var unit2 = View.findDrawableById("unit2");

        if (Sys.DeviceSettings.distanceUnits == Sys.DeviceSettings.UNIT_METRIC) {
            mUnit1String = Rez.Strings.unit1metric;
        } else {
            mUnit1String = Rez.Strings.unit1statute;
        }
        mUnit2String = Rez.Strings.unit2;

        unit1.setText(mUnit1String);
        unit2.setText(mUnit2String);

        return true;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and save it locally in this method.
    function compute(info) {
        var avg = info.averageSpeed;
        var speed = info.currentSpeed;

        if (avg == null || speed == null) {
            mStatus = UNKNOWN;
            mSpeed = 0.0;
            return;
        }

        if (Sys.DeviceSettings.distanceUnits == Sys.DeviceSettings.UNIT_METRIC) {
            speed = speed * 3.6;
            avg = avg * 3.6;
        } else {
            speed = speed * 2.23694;
            avg = avg * 2.23694;
        }

        if (info.timerState == Activity.TIMER_STATE_ON) {
            if (withinRange(speed, avg - 0.1, avg + 0.1)) {
                mStatus = EQUAL;
            } else if (speed < avg) {
                mStatus = SLOWER;
            } else if (speed > avg) {
                mStatus = FASTER;
            } else {
                mStatus = UNKNOWN;
            }
        } else {
            mStatus = PAUSED;
        }

        mSpeed = speed;
    }

    function onUpdate(dc) {
        View.findDrawableById("Background").setColor(getBackgroundColor());

        var label = View.findDrawableById("label");
        var speed = View.findDrawableById("value");
        var status = View.findDrawableById("status");
        var unit1 = View.findDrawableById("unit1");
        var unit2 = View.findDrawableById("unit2");

        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            label.setColor(Gfx.COLOR_WHITE);
            speed.setColor(Gfx.COLOR_WHITE);
            status.setColor(Gfx.COLOR_WHITE);
            unit1.setColor(Gfx.COLOR_WHITE);
            unit2.setColor(Gfx.COLOR_WHITE);
        } else {
            label.setColor(Gfx.COLOR_BLACK);
            speed.setColor(Gfx.COLOR_BLACK);
            status.setColor(Gfx.COLOR_BLACK);
            unit1.setColor(Gfx.COLOR_BLACK);
            unit2.setColor(Gfx.COLOR_BLACK);
        }
        var speedString = mSpeed.format(mFormatString);
        speed.setText(speedString);

        var statusString = "?";

        if (mStatus == EQUAL) {
            statusString = "=";
        } else if (mStatus == SLOWER) {
            statusString = "-";
        } else if (mStatus == FASTER) {
            statusString = "+";
        } else if (mStatus == PAUSED) {
            statusString = "~";
        } else if (mStatus == UNKNOWN) {
            statusString = "x";
        }

        var speedWidth = dc.getTextWidthInPixels(speedString, Gfx.FONT_LARGE);
        var statusWidth = dc.getTextWidthInPixels(statusString, Gfx.FONT_TINY);
        var largeHeight = Gfx.getFontHeight(Gfx.FONT_LARGE);
        var tinyHeight = Gfx.getFontHeight(Gfx.FONT_TINY);

        var offset = 0;
        if (mSpeed >= 10) {
            // for some reason getTextWidthInPixels overestimates the width when
            // the formatted string is 3 digits long
            offset = -8;
        }

        // to the right of speed, and above the horizontal centerline
        unit1.locX = speed.locX + speedWidth - 8 + offset;
        unit1.locY = speed.locY + tinyHeight / 2 - tinyHeight / 2;

        // to the right of speed, and below the horizontal centerline
        unit2.locX = unit1.locX;
        unit2.locY = speed.locY + tinyHeight / 2 + tinyHeight / 2;

        // to the left of speed, on the horizontal centerline
        status.locX = speed.locX - speedWidth / 2 - statusWidth / 2 - 8;
        status.locY = speed.locY;

        status.setText(statusString);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    function withinRange(value, lower, upper) {
        return value >= lower && value <= upper;
    }

}
