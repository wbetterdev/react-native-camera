package org.reactnative.camera.events;

import androidx.annotation.NonNull;
import androidx.core.util.Pools;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.Event;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import org.reactnative.camera.CameraViewManager;
import org.reactnative.barcodedetector.RNBarcodeDetector;

public class BarcodeDetectionErrorEvent extends Event<BarcodeDetectionErrorEvent> {

  private static final Pools.SynchronizedPool<BarcodeDetectionErrorEvent> EVENTS_POOL = new Pools.SynchronizedPool<>(3);
  private RNBarcodeDetector mBarcodeDetector;

  private BarcodeDetectionErrorEvent() {
  }

  public static BarcodeDetectionErrorEvent obtain(int surfaceId, int viewTag, RNBarcodeDetector barcodeDetector) {
    BarcodeDetectionErrorEvent event = EVENTS_POOL.acquire();
    if (event == null) {
      event = new BarcodeDetectionErrorEvent();
    }
    event.init(surfaceId, viewTag, barcodeDetector);
    return event;
  }

  private void init(int surfaceId, int viewTag, RNBarcodeDetector faceDetector) {
    super.init(surfaceId, viewTag);
    mBarcodeDetector = faceDetector;
  }

  @Override
  public short getCoalescingKey() {
    return 0;
  }

  @NonNull
  @Override
  public String getEventName() {
    return CameraViewManager.Events.EVENT_ON_BARCODE_DETECTION_ERROR.toString();
  }

  @Override
  public void dispatch(RCTEventEmitter rctEventEmitter) {
    rctEventEmitter.receiveEvent(getViewTag(), getEventName(), serializeEventData());
  }

  private WritableMap serializeEventData() {
    WritableMap map = Arguments.createMap();
    map.putBoolean("isOperational", mBarcodeDetector != null && mBarcodeDetector.isOperational());
    return map;
  }
}
