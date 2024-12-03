
import time

# beehivesec/rdpy:linux-amd64 (python2.7)

from rdpy.protocol.rdp import rdp
from twisted.internet import reactor


class MyRDPFactory(rdp.ClientFactory):

    def clientConnectionLost(self, connector, reason):
        reactor.stop()

    def clientConnectionFailed(self, connector, reason):
        reactor.stop()

    def buildObserver(self, controller, addr):
        controller.setUsername('NewRDPUser')
        controller.setPassword('SecureP@ssw0rd!')
        # RDP no NLA no SSL
        controller.setSecurityLevel(rdp.SecurityLevel.RDP_LEVEL_RDP)
        # RDP NLA
        # controller.setSecurityLevel(rdp.SecurityLevel.RDP_LEVEL_NLA)
        # RDP SSL
        # controller.setSecurityLevel(rdp.SecurityLevel.RDP_LEVEL_SSL)
        controller.setScreen(1024, 768)
        controller.setPerformanceSession()

        class MyObserver(rdp.RDPClientObserver):

            def _send_string(self, text):
                for c in text:
                    for pressed in (True, False):
                        reactor.callLater(
                            0, self._controller.sendKeyEventUnicode, ord(unicode(c)), pressed)

            def _send_keypress(self, scancode, extended=False):
                for pressed in (True, False):
                    reactor.callLater(
                        0, self._controller.sendKeyEventScancode, scancode, pressed, extended)

            def _send_combo(self, scancodes):
                for pressed in (True, False):
                    for code, extended in scancodes:
                        reactor.callLater(
                            0, self._controller.sendKeyEventScancode, code, pressed, extended)

            def _mouse_click(self, x, y, button):
                reactor.callLater(
                    0, self._controller.sendPointerEvent, x, y, button, True)
                reactor.callLater(
                    0, self._controller.sendPointerEvent, x, y, button, False)

            def _mouse_press(self, x, y, button, pressed=True):
                reactor.callLater(
                    0, self._controller.sendPointerEvent, x, y, button, pressed)

            def onReady(self):
                pass

            def onUpdate(self, destLeft, destTop, destRight, destBottom, width, height, bitsPerPixel, isCompress, data):
                """
                @summary: Notify bitmap update
                @param destLeft: xmin position
                @param destTop: ymin position
                @param destRight: xmax position because RDP can send bitmap with padding
                @param destBottom: ymax position because RDP can send bitmap with padding
                @param width: width of bitmap
                @param height: height of bitmap
                @param bitsPerPixel: number of bit per pixel
                @param isCompress: use RLE compression
                @param data: bitmap data
                """

            def onSessionReady(self):
                """
                @summary: Windows session is ready
                """

                # self._controller.sendPointerEvent(5, 760, 1, True)

                # Scancodes:
                # * http://www.win.tue.nl/~aeb/linux/kbd/scancodes-10.html
                # * https://msdn.microsoft.com/en-us/library/cc240584.aspx

                # For extended keys, leave off the e0 and pass extended=True

                def close_app():
                    # alt+f+x
                    self._send_combo(
                        [(0x38, False), (0x21, False), (0x2d, False)])

                def save_file():
                    self._send_string('test.txt')
                    self._send_combo([(0x38, False), (0x1f, False)])
                    reactor.callLater(1, close_app)

                def type_stuff():
                    self._send_string('echo "Testing..."\r\n')
                    self._send_string('echo "123..."\r\n')
                    self._send_combo([(0x1d, False), (0x1f, False)])
                    reactor.callLater(1, save_file)

                def move_mouse():
                    self._mouse_click(20, 60, 1)
                    self._mouse_click(20, 60, 1)

                def start_cmd():
                    self._send_string('cmd /K echo "It\'s alive!"')
                    self._send_keypress(0x1c)

                    reactor.callLater(1, type_stuff)

                # reactor.callLater(1, start_cmd)
                # reactor.callLater(1, move_mouse)

                # WIN + R
                self._send_combo([(0x5b, True), (0x13, False)])
                self._send_string('notepad')
                self._send_keypress(0x1c)
                time.sleep(3)
                reactor.callLater(1, type_stuff)
                time.sleep(3)
                # # WIN + R
                # self._send_combo([(0x5b, True), (0x13, False)])
                # self._send_string('mspaint')
                # self._send_keypress(0x1c)
                # time.sleep(3)
                # # Send Alt+Tab
                # self._send_combo([(0x38, False), (0x0F, False)])
                # time.sleep(3)
                # print "done"

            def onClose(self):
                """
                @summary: Call when stack is close
                """

        return MyObserver(controller)


reactor.connectTCP('54.227.254.62', 3389, MyRDPFactory())
reactor.run()
